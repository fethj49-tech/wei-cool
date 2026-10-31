package com.weicool.app

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Typeface
import android.os.Bundle
import android.view.Gravity
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class MainActivity : Activity() {

    private val executor = Executors.newSingleThreadExecutor()

    private lateinit var codeInput: EditText
    private lateinit var questionInput: EditText
    private lateinit var statusText: TextView
    private lateinit var answerText: TextView
    private lateinit var helpButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(20), dp(20), dp(20))
            setBackgroundColor(0xFFF7F7FA.toInt())
        }

        val scroll = ScrollView(this).apply {
            isFillViewport = true
            addView(content)
        }

        content.addView(TextView(this).apply {
            text = "Wei"
            textSize = 28f
            setTypeface(null, Typeface.BOLD)
        })

        content.addView(label("Your code"))
        codeInput = EditText(this).apply {
            hint = "Paste or type code here"
            minLines = 8
            gravity = Gravity.TOP or Gravity.START
            typeface = Typeface.MONOSPACE
            inputType = EditorInfo.TYPE_CLASS_TEXT or
                EditorInfo.TYPE_TEXT_FLAG_MULTI_LINE or
                EditorInfo.TYPE_TEXT_FLAG_NO_SUGGESTIONS
        }
        content.addView(codeInput, fieldParams())

        content.addView(label("What do you need help with?"))
        questionInput = EditText(this).apply {
            hint = "Explain this code, find a bug, suggest a fix..."
            minLines = 2
            gravity = Gravity.TOP or Gravity.START
            inputType = EditorInfo.TYPE_CLASS_TEXT or
                EditorInfo.TYPE_TEXT_FLAG_MULTI_LINE or
                EditorInfo.TYPE_TEXT_FLAG_CAP_SENTENCES
        }
        content.addView(questionInput, fieldParams())

        val buttons = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
        }

        buttons.addView(Button(this).apply {
            text = "Copy code"
            setOnClickListener { copyCode() }
        }, LinearLayout.LayoutParams(0, dp(48), 1f))

        helpButton = Button(this).apply {
            text = "Ask Wei"
            setOnClickListener { askWei() }
        }
        buttons.addView(helpButton, LinearLayout.LayoutParams(0, dp(48), 1f))
        content.addView(buttons)

        statusText = TextView(this).apply {
            setPadding(0, dp(12), 0, dp(4))
        }
        content.addView(statusText)

        answerText = TextView(this).apply {
            textSize = 16f
            setTextIsSelectable(true)
            setPadding(dp(12), dp(12), dp(12), dp(12))
            setBackgroundColor(0xFFFFFFFF.toInt())
        }
        content.addView(answerText)

        setContentView(scroll)
    }

    private fun askWei() {
        val code = codeInput.text.toString().trim()
        val question = questionInput.text.toString().trim()

        if (code.isEmpty() && question.isEmpty()) {
            statusText.text = "Enter code or a question first."
            return
        }

        helpButton.isEnabled = false
        statusText.text = "Getting help…"
        answerText.text = ""

        executor.execute {
            try {
                val connection = URL(
                    "https://YOUR_BACKEND_URL/v1/code-help"
                ).openConnection() as HttpURLConnection

                connection.requestMethod = "POST"
                connection.connectTimeout = 15_000
                connection.readTimeout = 60_000
                connection.doOutput = true
                connection.setRequestProperty(
                    "Content-Type",
                    "application/json; charset=utf-8"
                )

                val request = JSONObject()
                    .put("code", code)
                    .put("question", question)
                    .toString()

                connection.outputStream.use {
                    it.write(request.toByteArray(Charsets.UTF_8))
                }

                val statusCode = connection.responseCode
                val stream = if (statusCode in 200..299) {
                    connection.inputStream
                } else {
                    connection.errorStream
                }

                val body = stream?.bufferedReader()?.use { it.readText() }.orEmpty()
                connection.disconnect()

                if (statusCode !in 200..299) {
                    throw Exception("Server returned HTTP $statusCode")
                }

                val answer = JSONObject(body).optString("answer")
                if (answer.isBlank()) throw Exception("The server returned no answer.")

                runOnUiThread {
                    statusText.text = "Wei’s suggestion:"
                    answerText.text = answer
                    helpButton.isEnabled = true
                }
            } catch (e: Exception) {
                runOnUiThread {
                    statusText.text = "Couldn’t get a response: ${e.message}"
                    helpButton.isEnabled = true
                }
            }
        }
    }

    private fun copyCode() {
        val code = codeInput.text.toString()
        if (code.isBlank()) {
            statusText.text = "There’s no code to copy yet."
            return
        }

        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("Code", code))
        statusText.text = "Code copied."
    }

    private fun label(text: String) = TextView(this).apply {
        this.text = text
        textSize = 16f
        setTypeface(null, Typeface.BOLD)
        setPadding(0, dp(8), 0, dp(8))
    }

    private fun fieldParams() =
        LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            bottomMargin = dp(12)
        }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }
}
