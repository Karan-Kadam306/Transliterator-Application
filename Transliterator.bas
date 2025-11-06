Option Explicit

Private gTargetLanguage As String

Private Sub EnsureLanguageDefault()
	If gTargetLanguage = "" Then gTargetLanguage = "Hindi"
End Sub

' Module: Transliterator
' Purpose: Transliterate ASCII/Latin text to Devanagari (Hindi/Marathi) using a simple ITRANS-like scheme.
' Entry points:
'   - TransliterateSelectionOrDocument: Writer macro to transliterate selection or entire document
'   - TransliterateText: Core routine returning transliterated string

' Public macro: transliterate current selection (if any) or entire document
Public Sub TransliterateSelectionOrDocument()
	Dim oDoc As Object
	Dim oSelection As Object
	Dim hasSelection As Boolean

	oDoc = ThisComponent
	If IsNull(oDoc) Then Exit Sub

	If oDoc.supportsService("com.sun.star.text.TextDocument") = False Then
		MsgBox "Open a Writer document to use this macro.", 48, "Transliterator"
		Exit Sub
	End If

	oSelection = oDoc.CurrentSelection
	hasSelection = False
	If Not IsNull(oSelection) Then
		If oSelection.getCount() > 0 Then
			Dim firstSel As Object
			firstSel = oSelection.getByIndex(0)
			If firstSel.supportsService("com.sun.star.text.TextRange") Then
				If Len(CStr(firstSel.getString())) > 0 Then
					hasSelection = True
				End If
			End If
		End If
	End If

	If hasSelection Then
		TransliterateTextRange firstSel
	Else
		TransliterateWholeDocument oDoc
	End If
End Sub

' Public macro with preview/edit before applying
Public Sub TransliterateWithPreview()
	Call EnsureLanguageDefault
	Dim oDoc As Object
	Dim oSelection As Object
	Dim hasSelection As Boolean

	oDoc = ThisComponent
	If IsNull(oDoc) Then Exit Sub
	If oDoc.supportsService("com.sun.star.text.TextDocument") = False Then
		MsgBox "Open a Writer document to use this macro.", 48, "Transliterator"
		Exit Sub
	End If

	oSelection = oDoc.CurrentSelection
	hasSelection = False
	Dim firstSel As Object
	If Not IsNull(oSelection) Then
		If oSelection.getCount() > 0 Then
			firstSel = oSelection.getByIndex(0)
			If firstSel.supportsService("com.sun.star.text.TextRange") Then
				If Len(CStr(firstSel.getString())) > 0 Then
					hasSelection = True
				End If
			End If
		End If
	End If

	Dim src As String
	If hasSelection Then
		src = firstSel.getString()
	Else
		src = oDoc.getText().createTextCursor().getString()
	End If

	Dim dst As String
	dst = TransliterateText(src)

	Dim edited As String
	edited = InputBox("Preview and edit transliteration (" & gTargetLanguage & "):", "Transliterator", dst)
	If StrComp(edited, "", 0) = 0 And dst <> "" Then
		' If user cleared text explicitly, still apply; if they cancelled, InputBox returns "" too, but we cannot distinguish.
		' Offer a confirm dialog when empty
		Dim resp As Integer
		resp = MsgBox("Apply empty transliteration?", 33, "Transliterator")
		If resp <> 1 Then Exit Sub
	End If

	If hasSelection Then
		firstSel.setString edited
	Else
		Dim oText As Object, oCursor As Object
		oText = oDoc.getText()
		oCursor = oText.createTextCursor()
		oCursor.setString edited
	End If
End Sub

Private Sub TransliterateTextRange(oRange As Object)
	Dim src As String, dst As String
	src = oRange.getString()
	dst = TransliterateText(src)
	oRange.setString dst
End Sub

Private Sub TransliterateWholeDocument(oDoc As Object)
	Dim oText As Object
	oText = oDoc.getText()
	Dim oCursor As Object
	oCursor = oText.createTextCursor()
	Dim src As String, dst As String
	src = oCursor.getString()
	dst = TransliterateText(src)
	oCursor.setString dst
End Sub

' Core API to use in other contexts
Public Function TransliterateText(ByVal inputText As String) As String
    Call EnsureLanguageDefault
    Dim i As Long, n As Long
    Dim result As String
    Dim pendingConsonant As Boolean
    Dim consumed As Long

    i = 1
    n = Len(inputText)
    result = ""
    pendingConsonant = False

    Do While i <= n
        Dim matched As String
        Dim lat As String
        Dim dev As String
        
        ' 1) Others (spaces/punct/marks)
        matched = MatchFromMap(inputText, i, OtherLatin(), consumed)
        If consumed > 0 Then
            If pendingConsonant Then
                pendingConsonant = False
            End If
            result = result & MatchFromMapDev(matched, OtherLatin(), OtherDev())
            i = i + consumed
            GoTo ContinueLoop
        End If

        ' 2) Vowels
        lat = MatchLatin(inputText, i, VowelLatin(), consumed)
        If consumed > 0 Then
            dev = VowelDevForLatin(lat)
            If pendingConsonant Then
                result = result & MatraForLatin(lat)
                pendingConsonant = False
            Else
                result = result & dev
            End If
            i = i + consumed
            GoTo ContinueLoop
        End If

        ' 3) Consonants
        lat = MatchLatin(inputText, i, ConsonantLatin(), consumed)
        If consumed > 0 Then
            dev = ConsonantDevForLatin(lat)
            If pendingConsonant Then
                result = result & "्"
            End If
            result = result & dev
            pendingConsonant = True
            i = i + consumed
            GoTo ContinueLoop
        End If

        ' 4) Fallback: copy one char
        If pendingConsonant Then
            pendingConsonant = False
        End If
        result = result & Mid$(inputText, i, 1)
        i = i + 1

ContinueLoop:
    Loop

    ' Language-specific postprocessing (placeholder hooks)
    If StrComp(gTargetLanguage, "Hindi", 1) = 0 Then
        result = PostProcessHindi(result)
    ElseIf StrComp(gTargetLanguage, "Marathi", 1) = 0 Then
        result = PostProcessMarathi(result)
    End If

    TransliterateText = result
End Function

' -------- Mapping tables (ordered longest-first) --------

Private Function ConsonantLatin() As Variant
	ConsonantLatin = Array( _
		"ksh", "chh", "gh", "kh", "jh", _
		"th", "dh", "ph", "bh", "ny", "ng", "gn", _
		"tr", "gy", "shh", "sh", _
		"q", _
		"k", "g", "c", "j", "t", "d", "n", "p", "b", "m", "y", "r", "l", "L", "v", "w", "s", "h" _
	)
End Function

Private Function ConsonantDev() As Variant
	ConsonantDev = Array( _
		"क्ष", "छ", "घ", "ख", "झ", _
		"थ", "ध", "फ", "भ", "ञ", "ङ", "ङ", _
		"त्र", "ज्ञ", "ष", "श", _
		"क़", _
		"क", "ग", "च", "ज", "त", "द", "न", "प", "ब", "म", "य", "र", "ल", "ळ", "व", "व", "स", "ह" _
	)
End Function

Private Function VowelLatin() As Variant
	VowelLatin = Array( _
		"aai", "au", "ai", "oo", "uu", "ee", "ii", "aa", "a", "i", "u", "e", "o" _
	)
End Function

Private Function VowelDev() As Variant
	VowelDev = Array( _
		"ऐ", "औ", "ऐ", "ऊ", "ऊ", "ई", "ई", "आ", "अ", "इ", "उ", "ए", "ओ" _
	)
End Function

Private Function MatraLatin() As Variant
	MatraLatin = Array( _
		"aa", "ii", "ee", "uu", "oo", "ai", "au", "i", "u", "e", "o", "a" _
	)
End Function

Private Function MatraDev() As Variant
	MatraDev = Array( _
		"ा", "ी", "ी", "ू", "ू", "ै", "ौ", "ि", "ु", "े", "ो", "" _
	)
End Function

Private Function OtherLatin() As Variant
	OtherLatin = Array( _
		"||", "|", ".n", ".m", "~n", ".h", "OM", _
		" ", ",", ".", "-", "'", "\"", Chr$(10), Chr$(9) _
	)
End Function

Private Function OtherDev() As Variant
	OtherDev = Array( _
		"॥", "।", "ं", "ं", "ँ", "ः", "ॐ", _
		" ", ",", ".", "-", "'", "\"", Chr$(10), Chr$(9) _
	)
End Function

' -------- Mapping helpers --------

Private Function MatchLatin(ByVal s As String, ByVal pos As Long, arr As Variant, ByRef consumed As Long) As String
	Dim i As Long
	For i = LBound(arr) To UBound(arr)
		Dim tok As String
		tok = CStr(arr(i))
		If pos + Len(tok) - 1 <= Len(s) Then
			If StrComp(Mid$(s, pos, Len(tok)), tok, 1) = 0 Then
				MatchLatin = tok
				consumed = Len(tok)
				Exit Function
			End If
		End If
	Next i
	consumed = 0
	MatchLatin = ""
End Function

Private Function MatchFromMap(ByVal s As String, ByVal pos As Long, latArr As Variant, ByRef consumed As Long) As String
	Dim i As Long
	For i = LBound(latArr) To UBound(latArr)
		Dim tok As String
		tok = CStr(latArr(i))
		If pos + Len(tok) - 1 <= Len(s) Then
			If StrComp(Mid$(s, pos, Len(tok)), tok, 1) = 0 Then
				MatchFromMap = tok
				consumed = Len(tok)
				Exit Function
			End If
		End If
	Next i
	consumed = 0
	MatchFromMap = ""
End Function

Private Function IsSameArray(a As Variant, b As Variant) As Boolean
	IsSameArray = False ' Basic lacks pointer equality; unused beyond simple branch
End Function

Private Function ConsonantDevForLatin(ByVal lat As String) As String
	ConsonantDevForLatin = LookupParallel(lat, ConsonantLatin(), ConsonantDev())
End Function

Private Function VowelDevForLatin(ByVal lat As String) As String
	VowelDevForLatin = LookupParallel(lat, VowelLatin(), VowelDev())
End Function

Private Function MatraForLatin(ByVal lat As String) As String
	MatraForLatin = LookupParallel(lat, MatraLatin(), MatraDev())
End Function

Private Function LookupParallel(ByVal key As String, latArr As Variant, devArr As Variant) As String
	Dim i As Long
	For i = LBound(latArr) To UBound(latArr)
		If StrComp(CStr(latArr(i)), key, 1) = 0 Then
			LookupParallel = CStr(devArr(i))
			Exit Function
		End If
	Next i
	LookupParallel = key
End Function

Private Function MatchFromMapDev(ByVal key As String, latArr As Variant, devArr As Variant) As String
	MatchFromMapDev = LookupParallel(key, latArr, devArr)
End Function

Private Function PostProcessHindi(ByVal s As String) As String
	' Placeholder for Hindi-specific cleanup (e.g., nukta preferences, danda spacing)
	PostProcessHindi = s
End Function

Private Function PostProcessMarathi(ByVal s As String) As String
	' Placeholder for Marathi-specific tweaks (e.g., prefer "+ळ" mappings already enabled via 'L')
	PostProcessMarathi = s
End Function

' ----- Language toggles -----
Public Sub SetLanguageHindi()
	gTargetLanguage = "Hindi"
	MsgBox "Transliteration language set to Hindi.", 64, "Transliterator"
End Sub

Public Sub SetLanguageMarathi()
	gTargetLanguage = "Marathi"
	MsgBox "Transliteration language set to Marathi.", 64, "Transliterator"
End Sub

Public Function GetCurrentLanguage() As String
	Call EnsureLanguageDefault
	GetCurrentLanguage = gTargetLanguage
End Function


