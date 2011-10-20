nodemailer = require('nodemailer')
mustache   = require('mustache')
fs         = require('fs')

# Set up nodemailer
nodemailer.sendmail = true

# Load a mustache template from a file in the templates directory
loadTemplate = (file) ->
    try
        fs.readFileSync require('path').join(__dirname, "templates", file), "utf-8"
    catch err
        console.log "Email: error reading template: ", err

# Load the templates
plainTemplate = loadTemplate "error.plain.mustache"
htmlTemplate  = loadTemplate "error.html.mustache"

# Notifier
exports.executeNotification = (account, project, triggerText, event, options, target, errorCallback) ->
    # Make variables available in templates
    context =
        projectName: project.name
        projectSlug: project.slug
        errorId: event.errorHash
        appVersion: event.appEnvironment.appVersion
        eventMessage: event.causes[0].errorClass + ": " + event.causes[0].message
        eventLocation: event.causes[0].stacktrace[0].file + " at " + event.causes[0].stacktrace[0].lineNumber
        eventTrace: event.causes[0].stacktrace
        
    target.emailAddresses (error, emails) ->
        if error
            errorCallback "Error when retrieving emails! Contents: #{error}", true
            
        for email in emails
            do (email) ->
                # Send the email
                nodemailer.send_mail {
                    to : email
                    subject : triggerText + " on " + project.name
                    sender: 'Bugsnag <noreply@bugsnag.com>'
                    body: mustache.to_html plainTemplate, context
                    html: mustache.to_html htmlTemplate, context
                }, (err, result) ->
                    errorCallback "NotificationEmail: error sending email ", err, true if err