package com.waypointlattice.tripl.utils

import java.util.Locale

/**
 * Utility object for evaluating math expressions in amount text fields.
 * Supports basic arithmetic operations (+, -, *, x, ×, /, ÷, %, parentheses),
 * and handles percentage operations (e.g. 1000 - 15%, 100 + 10%).
 */
object MathEvaluator {

    fun tryParseAmount(input: String?): Double? {
        if (input.isNullOrBlank()) return null
        val trimmed = input.trim()

        val directDouble = trimmed.toDoubleOrNull()
        if (directDouble != null && !directDouble.isNaN() && !directDouble.isInfinite()) {
            return directDouble
        }

        return evaluate(trimmed)
    }

    fun hasOperator(text: String): Boolean {
        val cleaned = text.trim()
        if (cleaned.isEmpty()) return false
        val rest = if (cleaned.startsWith("-")) cleaned.substring(1) else cleaned
        return rest.contains("+") ||
                rest.contains("-") ||
                rest.contains("*") ||
                rest.contains("×") ||
                rest.contains("x") ||
                rest.contains("X") ||
                rest.contains("/") ||
                rest.contains("÷") ||
                rest.contains("%")
    }

    fun formatResult(value: Double): String {
        if (value.isNaN() || value.isInfinite()) return ""
        val rounded = Math.round(value)
        return if (Math.abs(value - rounded) < 1e-9 && Math.abs(value) < 1e12) {
            rounded.toString()
        } else {
            String.format(Locale.US, "%.2f", value)
        }
    }

    fun evaluate(expression: String): Double? {
        if (expression.trim().isEmpty()) return null

        return try {
            val sanitized = sanitize(expression)
            if (sanitized.isEmpty()) return null

            val tokens = tokenize(sanitized)
            if (tokens.isEmpty()) return null

            val parser = Parser(tokens)
            val result = parser.parse()

            if (result.isNaN() || result.isInfinite()) return null

            // Clean up IEEE 754 precision artifacts e.g. 17.490000000000002 -> 17.49
            val formatted = String.format(Locale.US, "%.10f", result)
            formatted.toDoubleOrNull()
        } catch (e: Exception) {
            null
        }
    }

    private fun sanitize(expr: String): String {
        return expr
            .replace("×", "*")
            .replace("x", "*")
            .replace("X", "*")
            .replace("÷", "/")
            .replace(" ", "")
    }

    private enum class TokenType { NUMBER, OPERATOR }

    private data class Token(val type: TokenType, val symbol: String, val value: Double? = null)

    private fun tokenize(expr: String): List<Token> {
        val tokens = mutableListOf<Token>()
        var i = 0

        while (i < expr.length) {
            val char = expr[i]

            if (char == '+' || char == '-' || char == '*' || char == '/' || char == '(' || char == ')' || char == '%') {
                tokens.add(Token(TokenType.OPERATOR, char.toString()))
                i++
            } else if (isDigitOrDot(char)) {
                val start = i
                while (i < expr.length && isDigitOrDot(expr[i])) {
                    i++
                }
                val numStr = expr.substring(start, i)
                val numVal = numStr.toDoubleOrNull() ?: throw IllegalArgumentException("Invalid number: $numStr")
                tokens.add(Token(TokenType.NUMBER, numStr, numVal))
            } else {
                i++
            }
        }
        return tokens
    }

    private fun isDigitOrDot(char: Char): Boolean {
        return char in '0'..'9' || char == '.'
    }

    private class Parser(private val tokens: List<Token>) {
        private var pos = 0

        private val current: Token?
            get() = if (pos < tokens.size) tokens[pos] else null

        fun parse(): Double {
            val result = parseAddSub()
            if (pos < tokens.size) {
                throw IllegalArgumentException("Unexpected token at position $pos: ${tokens[pos]}")
            }
            return result
        }

        private fun parseAddSub(): Double {
            var left = parseMulDiv()

            while (current != null && current!!.type == TokenType.OPERATOR) {
                val op = current!!.symbol
                if (op == "+" || op == "-") {
                    pos++
                    val right = parseMulDiv()
                    left = if (op == "+") left + right else left - right
                } else {
                    break
                }
            }
            return left
        }

        private fun parseMulDiv(): Double {
            var left = parseFactor()

            while (current != null && current!!.type == TokenType.OPERATOR) {
                val op = current!!.symbol
                if (op == "*" || op == "/" || op == "%") {
                    pos++
                    if (op == "%") {
                        left /= 100.0
                    } else {
                        val right = parseFactor()
                        if (op == "*") {
                            left *= right
                        } else {
                            if (right == 0.0) throw ArithmeticException("Division by zero")
                            left /= right
                        }
                    }
                } else {
                    break
                }
            }
            return left
        }

        private fun parseFactor(): Double {
            val cur = current ?: throw IllegalArgumentException("Unexpected end of expression")

            // Unary + or -
            if (cur.type == TokenType.OPERATOR && (cur.symbol == "+" || cur.symbol == "-")) {
                val op = cur.symbol
                pos++
                val factor = parseFactor()
                return if (op == "-") -factor else factor
            }

            // Parentheses
            if (cur.type == TokenType.OPERATOR && cur.symbol == "(") {
                pos++ // consume '('
                val valResult = parseAddSub()
                if (current == null || current!!.symbol != ")") {
                    throw IllegalArgumentException("Missing closing parenthesis")
                }
                pos++ // consume ')'

                if (current != null && current!!.symbol == "%") {
                    pos++
                    return valResult / 100.0
                }
                return valResult
            }

            // Number
            if (cur.type == TokenType.NUMBER) {
                val valNum = cur.value!!
                pos++

                if (current != null && current!!.symbol == "%") {
                    pos++
                    return valNum / 100.0
                }
                return valNum
            }

            throw IllegalArgumentException("Unexpected token: ${cur.symbol}")
        }
    }
}
