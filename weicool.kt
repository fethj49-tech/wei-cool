package com.weicool.app

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { MaterialTheme { WeiCoolApp() } }
    }
}

@Composable
fun WeiCoolApp() {
    val context = LocalContext.current
    val prefs = remember {
        context.getSharedPreferences("wei_cool_project", Context.MODE_PRIVATE)
    }
    val starterCode = "// Start building with Wei\n"

    var code by remember {
        mutableStateOf(prefs.getString("code", starterCode) ?: starterCode)
    }
    var input by remember { mutableStateOf("") }
    var console by remember { mutableStateOf("Console ready.") }
    var saveStatus by remember {
        mutableStateOf(if (prefs.contains("code")) "Saved project loaded" else "Not saved yet")
    }
    val messages = remember {
        mutableStateListOf("Wei: Offline starter mode is ready.")
    }

    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("Wei Cool", style = MaterialTheme.typography.headlineMedium)
        Text("Project: Untitled")

        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End
        ) {
            TextButton(onClick = {
                prefs.edit().putString("code", code).apply()
                saveStatus = "Saved on this device"
            }) {
                Text("Save")
            }

            Button(onClick = {
                console = "Preview prepared. Code execution is not enabled yet."
            }) {
                Text("▶ Play")
            }
        }

        Text(saveStatus)
        Text("Code editor")

        OutlinedTextField(
            value = code,
            onValueChange = { code = it },
            modifier = Modifier.fillMaxWidth().weight(1f),
            minLines = 6,
            label = { Text("Code") }
        )

        Text("Console: $console")

        Column(
            Modifier.weight(0.7f).verticalScroll(rememberScrollState())
        ) {
            messages.forEach { Text(it, Modifier.padding(vertical = 3.dp)) }
        }

        Row {
            OutlinedTextField(
                value = input,
                onValueChange = { input = it },
                modifier = Modifier.weight(1f),
                label = { Text("Ask Wei") }
            )

            Button(onClick = {
                val prompt = input.trim()
                if (prompt.isNotEmpty()) {
                    messages.add("You: $prompt")
                    messages.add(
                        if ("hello" in prompt.lowercase()) {
                            "Wei: Hello. I’m ready to help with your project."
                        } else {
                            "Wei: I’m in offline starter mode. Connect an AI model for broader assistance."
                        }
                    )
                    input = ""
                }
            }) {
                Text("Send")
            }
        }
    }
}
