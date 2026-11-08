// Supabase Edge Function: send-feedback-notification
// Sends an email notification using Resend when new feedback is submitted.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RequestPayload {
  feedbackId?: string;
}

serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Server misconfigured: missing Supabase environment variables." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse and validate request payload
    let payload: RequestPayload = {};
    try {
      payload = await req.json();
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid JSON payload." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { feedbackId } = payload;
    if (!feedbackId || typeof feedbackId !== "string" || feedbackId.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid 'feedbackId' parameter." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase admin client with service_role to bypass RLS and access feedback record
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false },
    });

    // 1. Fetch feedback record
    const { data: feedback, error: fetchError } = await supabase
      .from("app_feedback")
      .select("*")
      .eq("id", feedbackId)
      .maybeSingle();

    if (fetchError || !feedback) {
      return new Response(
        JSON.stringify({ error: `Feedback not found: ${fetchError?.message || "Record does not exist."}` }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Idempotency check: avoid sending duplicate emails
    if (feedback.email_status === "sent") {
      return new Response(
        JSON.stringify({ message: "Notification already sent.", status: "already_sent" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Read secrets for email sending
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const recipientEmail = Deno.env.get("FEEDBACK_RECIPIENT_EMAIL");
    const senderEmail = Deno.env.get("FEEDBACK_SENDER_EMAIL") || "Vehnicate Feedback <onboarding@resend.dev>";

    // If Resend is not configured, run in Mock / Dry-Run mode for testing
    const isMockMode = !resendApiKey || !recipientEmail;
    if (isMockMode) {
      console.log(`[Mock Mode] No Resend credentials provided. Simulating email notification for feedback: ${feedbackId}`);
    }

    // 4. Generate signed URLs for attachments (valid for 7 days)
    const attachmentItems: Array<{ fileName: string; signedUrl: string }> = [];
    const rawAttachments: string[] = feedback.attachment_urls || [];

    if (rawAttachments.length > 0) {
      const { data: signedUrls, error: storageError } = await supabase.storage
        .from("feedback-attachments")
        .createSignedUrls(rawAttachments, 60 * 60 * 24 * 7); // 7 days

      if (!storageError && signedUrls) {
        for (const item of signedUrls) {
          if (item.signedUrl) {
            const fileName = item.path?.split("/").pop() || "attachment";
            attachmentItems.push({
              fileName,
              signedUrl: item.signedUrl,
            });
          }
        }
      }
    }

    // 5. Build HTML Email Template
    const categoryTitle =
      feedback.category === "bug_report"
        ? "Bug Report"
        : feedback.category === "feature_request"
        ? "Feature Request"
        : "General Feedback";

    const categoryBadgeColor =
      feedback.category === "bug_report"
        ? "#e53e3e"
        : feedback.category === "feature_request"
        ? "#805ad5"
        : "#319795";

    const formattedTimestamp = new Date(feedback.created_at).toLocaleString("en-US", {
      timeZone: "Asia/Kolkata",
      dateStyle: "full",
      timeStyle: "long",
    });

    const attachmentsHtml =
      attachmentItems.length > 0
        ? `
          <div style="margin-top: 20px;">
            <h4 style="margin: 0 0 10px 0; color: #2d3748; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">Attached Screenshots (${attachmentItems.length})</h4>
            <div style="display: flex; flex-direction: column; gap: 8px;">
              ${attachmentItems
                .map(
                  (att, idx) => `
                <div style="background-color: #f7fafc; padding: 10px 14px; border-radius: 6px; border: 1px solid #e2e8f0;">
                  <a href="${att.signedUrl}" target="_blank" style="color: #6b46c1; text-decoration: none; font-weight: 500; font-size: 14px; display: inline-flex; align-items: center;">
                    📎 Attachment ${idx + 1}: ${att.fileName} &rarr;
                  </a>
                  <span style="display: block; font-size: 11px; color: #718096; margin-top: 3px;">(Secure download link valid for 7 days)</span>
                </div>
              `
                )
                .join("")}
            </div>
          </div>
        `
        : `<p style="color: #718096; font-size: 13px; margin-top: 15px; font-style: italic;">No screenshots attached.</p>`;

    const emailHtml = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>New Feedback: ${categoryTitle}</title>
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0f101d; margin: 0; padding: 24px; color: #1a202c;">
          <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.3);">
            
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #111322 0%, #201a40 100%); padding: 28px 24px; text-align: left; border-bottom: 2px solid #6b46c1;">
              <span style="font-size: 20px; font-weight: bold; color: #ffffff; letter-spacing: 1px;">VEHNICATE</span>
              <span style="display: inline-block; margin-left: 10px; background-color: ${categoryBadgeColor}; color: #ffffff; font-size: 11px; font-weight: 600; text-transform: uppercase; padding: 3px 10px; border-radius: 12px; letter-spacing: 0.5px;">
                ${categoryTitle}
              </span>
              <h2 style="color: #ffffff; margin: 12px 0 0 0; font-size: 18px; font-weight: 600;">New User Feedback Received</h2>
            </div>

            <!-- Body -->
            <div style="padding: 24px;">
              
              <!-- Description Section -->
              <div style="margin-bottom: 24px;">
                <h4 style="margin: 0 0 8px 0; color: #4a5568; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px;">User Description</h4>
                <div style="background-color: #edf2f7; padding: 16px; border-radius: 8px; font-size: 15px; line-height: 1.6; color: #1a202c; white-space: pre-wrap; border-left: 4px solid #6b46c1;">${feedback.description}</div>
              </div>

              <!-- Attachments -->
              ${attachmentsHtml}

              <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 24px 0;" />

              <!-- Device & Metadata Section -->
              <div>
                <h4 style="margin: 0 0 12px 0; color: #4a5568; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px;">Technical Metadata</h4>
                <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
                  <tr>
                    <td style="padding: 6px 0; color: #718096; width: 35%;">User ID:</td>
                    <td style="padding: 6px 0; color: #1a202c; font-weight: 500; font-family: monospace;">${feedback.user_id || "Anonymous"}</td>
                  </tr>
                  <tr>
                    <td style="padding: 6px 0; color: #718096;">App Version:</td>
                    <td style="padding: 6px 0; color: #1a202c; font-weight: 500;">${feedback.app_version || "Unknown"} (Build ${feedback.build_number || "N/A"})</td>
                  </tr>
                  <tr>
                    <td style="padding: 6px 0; color: #718096;">Device Model:</td>
                    <td style="padding: 6px 0; color: #1a202c; font-weight: 500;">${feedback.device_model || "Unknown"}</td>
                  </tr>
                  <tr>
                    <td style="padding: 6px 0; color: #718096;">Operating System:</td>
                    <td style="padding: 6px 0; color: #1a202c; font-weight: 500;">${feedback.os_version || "Unknown"}</td>
                  </tr>
                  <tr>
                    <td style="padding: 6px 0; color: #718096;">Submission Time:</td>
                    <td style="padding: 6px 0; color: #1a202c; font-weight: 500;">${formattedTimestamp} (IST)</td>
                  </tr>
                  <tr>
                    <td style="padding: 6px 0; color: #718096;">Feedback ID:</td>
                    <td style="padding: 6px 0; color: #718096; font-size: 11px; font-family: monospace;">${feedback.id}</td>
                  </tr>
                </table>
              </div>

            </div>

            <!-- Footer -->
            <div style="background-color: #f7fafc; padding: 14px 24px; text-align: center; border-top: 1px solid #edf2f7; font-size: 12px; color: #a0aec0;">
              Automated message from Vehnicate App Support System
            </div>
          </div>
        </body>
      </html>
    `;

    // 6. Send email via Resend (or simulate in Mock Mode)
    let resendData: { id?: string } = { id: `mock-${Date.now()}` };

    if (!isMockMode) {
      const resendResponse = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${resendApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: senderEmail,
          to: [recipientEmail],
          subject: `[Vehnicate ${categoryTitle}] New submission from ${feedback.device_model || "User"}`,
          html: emailHtml,
        }),
      });

      if (!resendResponse.ok) {
        const resendErrText = await resendResponse.text();
        const errorMsg = `Resend API failed (${resendResponse.status}): ${resendErrText}`;
        await supabase
          .from("app_feedback")
          .update({ email_status: "failed", email_error: errorMsg })
          .eq("id", feedbackId);

        return new Response(
          JSON.stringify({ error: errorMsg }),
          { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      resendData = await resendResponse.json();
    } else {
      console.log(`[Mock Mode] Email delivery simulated successfully for feedback ${feedbackId}`);
    }

    // 7. Update status to 'sent'
    await supabase
      .from("app_feedback")
      .update({
        email_status: "sent",
        email_error: isMockMode ? "Mock mode: simulated sent (Resend not configured)" : null,
      })
      .eq("id", feedbackId);

    return new Response(
      JSON.stringify({
        success: true,
        status: "sent",
        isMockMode,
        resendId: resendData.id,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorString = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: `Internal function error: ${errorString}` }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

