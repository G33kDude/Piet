#NoEnv

Width := 20
Height := 10
tSize := 14

; Start gdi+
If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}

OnExit, ExitSub

Options := "w20 h20 HwndHwnd Border"

Gui, +HwndGuiHwnd
Gui, Margin, 5, 5

Menu :=
( LTRIM JOIN
[
	{"Name": "File", "Label": [
		{"Name": "Load", "Label": "LoadFile"},
		{"Name": "Save", "Label": "SaveFile"},
		{"Name": "Run", "Label": "RunFile"}
	]},
	{"Name": "Grid", "Label": [
		{"Name": "Width", "Label": [
			{"Name": "Expand", "Label": "GrowW"},
			{"Name": "Contract", "Label": "ShrinkW"}
		]},
		{"Name": "Height", "Label": [
			{"Name": "Expand", "Label": "GrowH"},
			{"Name": "Contract", "Label": "ShrinkH"}
		]},
		{"Name": "Shift", "Label": [
			{"Name": "Up", "Label": "Dummy"},
			{"Name": "Down", "Label": "Dummy"},
			{"Name": "Left", "Label": "Dummy"},
			{"Name": "Right", "Label": "Dummy"}
		]}
	]}
]
)

Gui, Menu, % MakeMenu(Menu)

Progresses := []

; Reds
Gui, Add, Progress, %Options% x5 y5 Section
Progresses[hWnd] := "FFC0C0"
Gui, Add, Progress, %Options% x+2 yS
Progresses[hWnd] := "FF0000"
Gui, Add, Progress, %Options% x+2 yS
Progresses[hWnd] := "C00000"

; White
Gui, Add, Progress, %Options% x+2 ys
Progresses[hWnd] := "FFFFFF"

Gui, Add, Button, w32 h21 x+2 ys-1 gGrowW, W+
Gui, Add, Button, w32 h21 x+1 ys-1 gGrowH, V+

; Yellows
Gui, Add, Progress, %Options% xS yS+22 Section
Progresses[hWnd] := "FFFFC0"
Gui, Add, Progress, %Options% x+2 yS
Progresses[hWnd] := "FFFF00"
Gui, Add, Progress, %Options% x+2 yS
Progresses[hWnd] := "C0C000"

; Black
Gui, Add, Progress, %Options% x+2 ys
Progresses[hWnd] := "000000"

Gui, Add, Button, w32 h21 x+2 ys-1 gShrinkW, W-
Gui, Add, Button, w32 h21 x+1 ys-1 gShrinkH, V-

; Greens
Gui, Add, Progress, %Options% xS yS+22 Section
Progresses[hWnd] := "C0FFC0"
Gui, Add, Progress, %Options% x+2 ys
Progresses[hWnd] := "00FF00"
Gui, Add, Progress, %Options% x+2 ys
Progresses[hWnd] := "00C000"

; --- Back selected color ---
Gui, Add, Progress, Border w64 h64 BackgroundWhite hwndBack x+2 ys

Gui, Font, s14, WingDings
Gui, Add, Text, w20 h20 x+2 ys Center, Ê
Gui, Font,,

; Cyans
Gui, Add, Progress, %Options% xS yS+22 Section
Progresses[hWnd] := "C0FFFF"
Gui, Add, Progress, %Options% x+2 ys
Progresses[hWnd] := "00FFFF"
Gui, Add, Progress, %Options% x+2 ys
Progresses[hWnd] := "00C0C0"

; --- Front selected color ---
Gui, Add, Progress, Border w64 h64 BackgroundBlack hwndFront x+24 ys

; Blues
Gui, Add, Progress, %Options% xS yS+22 Section
Progresses[hWnd] := "C0C0FF"
Gui, Add, Progress, %Options% x+2 ys
Progresses[hWnd] := "0000FF"
Gui, Add, Progress, %Options% x+2 ys
Progresses[hWnd] := "0000C0"

; Magentas
Gui, Add, Progress, %Options% xS yS+22 Section
Progresses[hWnd] := "FFC0FF"
Gui, Add, Progress, %Options% x+2 ys
Progresses[hWnd] := "FF00FF"
Gui, Add, Progress, %Options% x+2 ys
Progresses[hWnd] := "C000C0"


IndexToColor := [["FFC0C0", "FF0000", "C00000"]
, ["FFFFC0", "FFFF00", "C0C000"]
, ["C0FFC0", "00FF00", "00C000"]
, ["C0FFFF", "00FFFF", "00C0C0"]
, ["C0C0FF", "0000FF", "0000C0"]
, ["FFC0FF", "FF00FF", "C000C0"]]

ColorToIndex := []
for x, Column in IndexToColor
	for y, Color in Column
		ColorToIndex[Color] := [x, y]

Size := "w32 h21"
Norm := Size " x+1 ys"
Sect := Size " y+1 xs Section"

Gui, Add, Button, %Size% gOp vOp00 x160 y4 Section, nop
Gui, Add, Button, %Norm% gOp vOp01, push
Gui, Add, Button, %Norm% gOp vOp02, pop
Gui, Add, Button, %Sect% gOp vOp10, add
Gui, Add, Button, %Norm% gOp vOp11, sub
Gui, Add, Button, %Norm% gOp vOp12, mul
Gui, Add, Button, %Sect% gOp vOp20, div
Gui, Add, Button, %Norm% gOp vOp21, mod
Gui, Add, Button, %Norm% gOp vOp22, not
Gui, Add, Button, %Sect% gOp vOp30, grtr
Gui, Add, Button, %Norm% gOp vOp31, ptr
Gui, Add, Button, %Norm% gOp vOp32, swch
Gui, Add, Button, %Sect% gOp vOp40, dup
Gui, Add, Button, %Norm% gOp vOp41, roll
Gui, Add, Button, %Norm% gOp vOp42, inN
Gui, Add, Button, %Sect% gOp vOp50, inC
Gui, Add, Button, %Norm% gOp vOp51, outN
Gui, Add, Button, %Norm% gOp vOp52, outC

w := Width * tSize, h := Height * tSize
EditorX := 5, EditorY := 140
Gui, Add, Progress, x5 y140 w%w% h%h% hwndGdipHwnd, 0

Editor := new Editor(GdipHwnd, Width, Height, tSize, "FFFFFF")

BackColor := "FFFFFF"
FrontColor := "000000"

for hWnd, Color in Progresses
	GuiControl, +Background%Color%, %hWnd%

OnMessage(0x200, "WM_MOUSEMOVE")

OnMessage(0x201, "WM_BUTTONDOWN")
OnMessage(0x202, "WM_BUTTONUP")
OnMessage(0x203, "WM_LBUTTONDBLCLK")

OnMessage(0x204, "WM_BUTTONDOWN")
OnMessage(0x205, "WM_BUTTONUP")
;OnMessage(0x206, "WM_RBUTTONDBLCLK")

OnMessage(0x207, "WM_MBUTTONDOWN")

OnMessage(0xF, "WM_PAINT")

;OnMessage(0x84, "WM_NCHITTEST")

Gui, Show

Editor.Draw()
return

Op:
Match1 := Match2 := ""
RegExMatch(A_GuiControl, "Op(\d)(\d)", Match)

Index := ColorToIndex[FrontColor]
x := Index[1] + Match1
if x > 6
	x -= 6
y := Index[2] + Match2
if y > 3
	y -= 3

FrontColor := IndexToColor[x, y]

GuiControl, -Redraw, %Back%
GuiControl, +Background%BackColor%, %Back%
Sleep, 50
GuiControl, +Background%FrontColor%, %Front%
GuiControl, +Redraw, %Back%
return

GrowW:
Editor.Resize(Editor.Width+1, Editor.Height)
return

ShrinkW:
Editor.Resize(Editor.Width-1, Editor.Height)
return

GrowH:
Editor.Resize(Editor.Width, Editor.Height+1)
return

ShrinkH:
Editor.Resize(Editor.Width, Editor.Height-1)
return

LoadFile:
FileSelectFile, FilePath,,,, Source Files (*.png; *.bmp)
Editor.Import(FilePath, 1)
return

SaveFile:
FileSelectFile, FilePath, S,,, Source Files (*.png)
Editor.Export(FilePath, 1)
return

RunFile:
Run, Piet_Interpreter.ahk %FilePath%
return

Dummy:
return

WM_MBUTTONDOWN(wParam, lParam, Msg, hWnd)
{
	global Editor, FrontColor
	
	Pos := LOHIWORD(lParam)
	x := Pos.LO, y := Pos.HI
	
	if (hWnd == Editor.hWnd)
	{
		Pos := Editor.PixelToCodel(x, y)
		Editor.Flood(Pos[1], Pos[2], FrontColor)
	}
}

MakeMenu(Array)
{
	Name := &Array
	
	for each, Entry in Array
	{
		Entry.Name
		if IsObject(Entry.Label)
			Menu, %Name%, Add, % Entry.Name, % ":" MakeMenu(Entry.Label)
		else
			Menu, %Name%, Add, % Entry.Name, % Entry.Label
	}
	
	return Name
}

WM_RBUTTONDBLCLK(p*)
{
	global Editor
	Editor.Resize(Editor.Width-1, Editor.Height-1)
	;Editor.Update()
}

WM_PAINT(wParam, lParam, Msg, hWnd)
{
	global Editor
	Sleep, 0 ; Needed for unminimize
	Editor.Draw()
}

WM_BUTTONDOWN(wParam, lParam, Msg, hWnd)
{
	global Editor, Progresses, CurrentColor
	global Front, FrontColor, Back, BackColor
	global GuihWnd, ButtonDown
	
	Pos := LOHIWORD(lParam)
	x := Pos.LO, y := Pos.HI
	
	if (Progresses.HasKey(hWnd))
	{
		Color := Progresses[hWnd]
		
		if (Msg < 0x204)
			FrontColor := Color
		Else
			BackColor := Color
		
		GuiControl, -Redraw, %Back%
		GuiControl, +Background%BackColor%, %Back%
		Sleep, 50
		GuiControl, +Background%FrontColor%, %Front%
		GuiControl, +Redraw, %Back%
	}
	else if (hWnd == Editor.hWnd)
	{
		Pos := Editor.PixelToCodel(x, y)
		CurrentColor := Msg < 0x204 ? FrontColor : BackColor
		Editor.SetColor(Pos[1], Pos[2], CurrentColor)
		Editor.Draw()
		ButtonDown := Pos
	}
}

WM_MOUSEMOVE(wParam, lParam, Msg, hWnd)
{
	global Editor, ButtonDown, CurrentColor
	global FrontColor, BackColor
	global MoveW, MoveH
	static ButtonMove
	
	Pos := LOHIWORD(lParam)
	x := Pos.LO, y := Pos.HI
	
	if (ButtonDown && hWnd == Editor.hWnd)
	{
		ButtonMove := Editor.PixelToCodel(x, y)
		
		if !(wParam & 3)
		{
			WM_BUTTONUP(wParam, lParam, Msg, hWnd)
			return
		}
		
		OldW := MoveW, OldH := MoveH
		MoveW := Range(ButtonDown[1], ButtonMove[1])
		MoveH := Range(ButtonDown[2], ButtonMove[2])
		
		for x in OldW
			for y in OldH
				if !(MoveW.HasKey(x) && MoveH.HasKey(y))
					Editor.UpdateColor(x, y)
		
		;Color := wParam & 1 ? FrontColor : BackColor
		
		for x in MoveW
			for y in MoveH
				if !(OldW.HasKey(x) && OldH.HasKey(y))
					Editor.ChangeColor(x, y, CurrentColor)
		
		Editor.Draw()
	}
}

WM_BUTTONUP(wParam, lParam, Msg, hWnd)
{
	global ButtonDown, MoveW, MoveH, CurrentColor
	
	if (ButtonDown)
	{
		ButtonDown := ""
		
		for x in MoveW
			for y in MoveH
				Editor.SetColor(x, y, CurrentColor)
		
		MoveW := "", MoveH := ""
		
		Editor.Draw()
	}
}

GuiClose:
ExitApp
return

ExitSub:
Editor := ""
Gdip_Shutdown(pToken)
ExitApp

class Editor
{
	__New(hWnd, Width, Height, tSize, BG="FFFFFF")
	{
		this.hWnd := hWnd
		this.Width := Width
		this.Height := Height
		this.tSize := tSize
		
		; Needed to make progress bar redraw correctly on resize
		Control, ExStyle, -0x20000,, % "ahk_id " this.hWnd
		
		GuiControlGet, g, Pos, %hWnd%
		this.gX := gX, this.gY := gY
		this.gW := Width*tSize
		this.gH := Height*tSize
		
		this.Grid := []
		Loop, % Width
		{
			x := A_Index
			Loop, % Height
			{
				y := A_Index
				this.Grid[x, y] := BG
			}
		}
		
		this.hDC_Window := GetDC(this.hWnd)
		this.hDC := CreateCompatibleDC()
		this.hDIB := CreateDIBSection(this.gW, this.gH)
		SelectObject(this.hDC, this.hDIB)
		this.G := Gdip_GraphicsFromHDC(this.hDC)
		
		GuiControl, MoveDraw, % this.hWnd, % "w" gW-1 " h" gH-1
		GuiControl, MoveDraw, % this.hWnd, % "w" gW " h" gH
		this.Update()
		
		return this
	}
	
	Import(FileName, CodelSize=10)
	{
		if !(pBitmap := Gdip_CreateBitmapFromFile(FileName))
			return "Invalid file"
		
		Gdip_GetDimensions(pBitmap, Width, Height)
		
		Width //= CodelSize, Height //= CodelSize
		
		if (Width > 200 || Height > 200)
		{
			Gdip_DisposeImage(pBitmap)
			return "Image too large"
		}
		
		this.Resize(Width, Height)
		
		Loop, % Width
		{
			x := A_Index - 1
			Loop, % Height
			{
				y := A_Index - 1
				ARGB := Gdip_GetPixel(pBitmap, x * CodelSize, y * codelSize)
				this.Grid[x+1, y+1] := this.ARGB(ARGB)
			}
		}
		
		Gdip_DisposeImage(pBitmap)
		this.UpdateSquares()
		this.Draw()
	}
	
	Export(FileName, CodelSize=10)
	{
		Width := this.Width * CodelSize
		Height := This.Height * CodelSize
		pBitmap := Gdip_CreateBitmap(Width, Height)
		pGraphics := Gdip_GraphicsFromImage(pBitmap)
		
		for x, Column in this.Grid
			for y, Color in Column
				Gdip_FillRectangle(pGraphics, this.Brushes[Color], (x-1)*CodelSize, (y-1)*CodelSize, CodelSize, CodelSize)
		
		Gdip_DeleteGraphics(pGraphics)
		
		
		if Gdip_SaveBitmapToFile(pBitmap, FileName, 100)
			Gdip_SaveBitmapToFile(pBitmap, FileName ".png", 100)
		
		Gdip_DisposeImage(pBitmap)
	}
	
	ARGB(ARGB)
	{
		for k, v in [ARGB >> 16, ARGB >> 8, ARGB]
			v &= 0xFF, Out .= (v < 96 ? "00" : (v > 223 ? "FF" : "C0"))
		return Out
	}
	
	Update()
	{
		this.UpdateGrid(), this.UpdateSquares()
	}
	
	UpdateGrid()
	{
		; Draw gray "lines" (All but line will be covered by codels)
		pBrush := Gdip_BrushCreateSolid(0xFFC0C0C0)
		Gdip_FillRectangle(this.G, pBrush, 0, 0, this.gW, this.gH)
		Gdip_DeleteBrush(pBrush)
		
		; Draw white lines
		pBrush := Gdip_BrushCreateSolid(0xFFFFFFFF)
		Loop, % this.Width
			Gdip_FillRectangle(this.G, pBrush, A_Index*this.tSize - 1, 0, 1, this.gH)
		Loop, % this.Height
			Gdip_FillRectangle(this.G, pBrush, 0, A_Index*this.tSize - 1, this.gW, 1)
		Gdip_DeleteBrush(pBrush)
	}
	
	UpdateSquares()
	{
		for x, Column in this.Grid
			for y, Color in Column
				this.ChangeColor(x, y, Color)
	}
	
	Draw()
	{
		BitBlt(this.hDC_Window, 0, 0, this.gW, this.gH, this.hDC, 0, 0)
	}
	
	ChangeColor(x, y, Color)
	{
		xPos := (x-1) * this.tSize + 1
		yPos := (y-1) * this.tSize + 1
		t := this.tSize - 2
		
		if !this.Brushes.HasKey(Color)
			this.Brushes[Color] := Gdip_BrushCreateSolid("0xFF" Color)
		
		Gdip_FillRectangle(this.G, this.Brushes[Color], xPos, yPos, t, t)
	}
	
	UpdateColor(x, y)
	{
		this.ChangeColor(x, y, this.Grid[x, y])
	}
	
	SetColor(x, y, Color)
	{
		this.Grid[x, y] := Color
		this.ChangeColor(x, y, Color)
	}
	
	PixelToCodel(x, y)
	{
		return [x//this.tSize + 1, y//this.tSize + 1]
	}
	
	Flood(x, y, NewColor)
	{
		;this._Flood(x, y, NewColor)
		Stack := [[x, y]]
		
		while (Pos := Stack.Remove(1))
		{
			x := Pos[1], y := Pos[2]
			Color := this.Grid[x, y]
			
			if (Color == NewColor)
				Continue
			
			this.Grid[x, y] := NewColor
			
			if (this.Grid[x+1, y] == Color)
				Stack.Insert([x+1, y])
			if (this.Grid[x-1, y] == Color)
				Stack.Insert([x-1, y])
			if (this.Grid[x, y+1] == Color)
				Stack.Insert([x, y+1])
			if (this.Grid[x, y-1] == Color)
				Stack.Insert([x, y-1])
		}
		
		this.UpdateSquares()
		this.Draw()
	}
	
	__Delete()
	{
		for Color, pBrush in this.Brushes
			Gdip_DeleteBrush(pBrush)
		
		Gdip_DeleteGraphics(this.G)
		DeleteObject(this.hDIB)
		DeleteDC(this.hDC)
		ReleaseDC(this.hDC_Window)
	}
	
	Resize(w, h)
	{
		; Remove old squares
		Loop, % this.Width
		{
			x := A_Index
			
			; Whole column can be removed
			if (x > w)
			{
				this.Grid.Remove(x)
				Continue
			}
			
			Loop, % this.Height
				if (A_Index > h)
					this.Grid[x].Remove(A_Index)
		}
		
		; Update sizes
		this.Width := w
		this.Height := h
		this.gW := this.tSize * w
		this.gH := this.tSize * h
		
		Gdip_DeleteGraphics(this.G)
		DeleteObject(this.hDIB)
		DeleteDC(this.hDC)
		this.hDC := CreateCompatibleDC()
		this.hDIB := CreateDIBSection(this.gW, this.gH)
		SelectObject(this.hDC, this.hDIB)
		this.G := Gdip_GraphicsFromHDC(this.hDC)
		
		; Add new squares
		Loop, % w
		{
			x := A_Index
			Loop, % h
				if (this.Grid[x, A_Index] == "")
					this.Grid[x, A_Index] := "FFFFFF"
		}
		
		GuiControl, Move, % this.hWnd, % "w" this.gW " h" this.gH
		Gui, Show, AutoSize
		
		this.Update()
		this.Draw()
	}
}

LOHIWORD(WORD)
{
	return {"LO": WORD & 0xFFFF, "HI": (WORD >> 16) & 0xFFFF}
}

Equals(arr1, arr2)
{
	for key, val in arr1
		if (arr2[key] != val)
			return false
	for key, val in arr2
		if (arr1[key] != val)
			return false
	return true
}

Range(Min, Max, Step=1)
{
	if (Min > Max)
		i := Max, Max := Min
	Else
		i := Min
	
	Out := []
	while (i <= Max)
	{
		Out.Insert(i, true)
		i += Step
	}
	return Out
}

Invert(Array)
{
	Out := []
	for Key, Value in Array
		Out[Value] := Key
	return Out
}