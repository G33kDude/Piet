DllCall("AllocConsole")

;New File; Start gdi+
If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}
OnExit, ExitSub

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

CodelSize := 1
if %1%
	sFile = %1%
else
	FileSelectFile, sFile

Gdip_Shutdown(pToken)


Wait := 0
Loop
{
	Codel := GetCodel(Pixel[1], Pixel[2], Grid)
	;DrawCodel(Codel, Grid)
	
	Wait := 0
	While Wait < 8
	{
		NextPixel := GetNextPixel(DP, CC, Codel)
		
		if (PointOutBounds(NextPixel, 1, 1, Width, Height)
			|| Grid[NextPixel*] == "000000")
			{
				CC := !CC
				NextPixel := GetNextPixel(DP, CC, Codel)
				
				if (PointOutBounds(NextPixel, 1, 1, Width, Height)
					|| Grid[NextPixel*] == "000000")
				{
					DP := RotateDP(DP)
					Wait++
					Continue
					}
			}
		
		Break
	}
	
	if (Wait == 8) ; stuck, end program
		Break
	
	
	
	While (Grid[NextPixel*] == "FFFFFF")
	{
		TmpPixel := NextPixel.Clone()
		
		Wait := 0
		Loop, 8
		{
			While Grid[TmpPixel*] == "FFFFFF"
				TmpPixel := AddDPToPoint(TmpPixel, DP)
			
			if (PointOutBounds(TmpPixel, 1, 1, Width, Height)
				|| Grid[TmpPixel*] == "000000")
				{
					TmpPixel := AddDPToPoint(TmpPixel, RotateDP(DP, 2))
					
					Wait++
					CC := !CC
					DP := RotateDP(DP)
					Continue
				}
			
			Break
		}
		
		if Wait >= 7
			Break, 2
		
		Pixel := NextPixel := TmpPixel
		
	}
	
	Op := GetOperation(Grid[Pixel*], Grid[NextPixel*])
	
	;MsgBox, Step
	Pixel := NextPixel
}

MsgBox, Wait timed out
MsgBox, % """" StdOut """"
ExitApp
return

ExitSub:
ExitApp

GetOperation(OldColor, NewColor)
{
	global IndexToColor, ColorToIndex
	
	OldPos := ColorToIndex[OldColor].Clone()
	NewPos := ColorToIndex[NewColor].Clone()
	
	
	if (NewPos[1] < OldPos[1])
		NewPos[1] += 6
	if (NewPos[2] < OldPos[2])
		NewPos[2] += 3
	
	
	
	Diff := NewPos[1] - OldPos[1]
	. "," NewPos[2] - OldPos[2]
	
	return Diff
}

GetNextPixel(DP, CC, Codel)
{
	if (DP == 0) ; Up
	{
		if CC ; Right
			Pixel := GetVCorner(Codel, True, False) ; Top Right
		else ; Left
			Pixel := GetVCorner(Codel, True, True) ; Top Left
	}
	if (DP == 1) ; Right
	{
		if CC ; Right
			Pixel := GetHCorner(Codel, False, False) ; Right Bottom
		else ; Left
			Pixel := GetHCorner(Codel, False, True) ; Right Top
	}
	else if (DP == 2) ; Down
	{
		if CC ; Right 
			Pixel := GetVCorner(Codel, False, True) ; Bottom Left
		else ; Left
			Pixel := GetVCorner(Codel, False, False) ; Bottom Right
	}
	else if (DP == 3) ; Left
	{
		if CC ; Right
			Pixel := GetHCorner(Codel, True, True) ; Left Top
		else ; Left
			Pixel := GetHCorner(Codel, True, False) ; Left Bottom
	}
	
	return AddDPToPoint(Pixel, DP)
}

AddDPToPoint(Point, DP)
{
	Point := Point.Clone()
	if (DP == 0)
		Point[2] -= 1
	if (DP == 1)
		Point[1] += 1
	if (DP == 2)
		Point[2] += 1
	if (DP == 3)
		Point[1] -= 1
	return Point
}

RotateDP(DP, n=1)
{
	DP += n
	While DP > 3
		DP -= 4
	While DP < 0
		DP += 4
	return DP
}

DrawCodel(Codel, Grid)
{
	static GText
	;return
	if !GText
	{
		Gui, Codel:Font, s6, Courier New
		Gui, Codel:Add, Text, w800 h600 vGText
		Gui, Codel:Show
		GText := True
	}
	Out := []
	for x, Column in Grid
	{
		for y, Color in Column
		{
			if (Codel[x, y])
				Out[y, x] := "â™¥"
			Else
			{
				if Color in FFC0C0,FF0000,C00000
					Out[y, x] := "R"
				else if Color in FFFFC0,FFFF00,C0C000
					Out[y, x] := "Y"
				else if Color in C0FFC0,00FF00,00C000
					Out[y, x] := "G"
				else if Color in C0FFFF,00FFFF,00C0C0
					Out[y, x] := "C"
				else if Color in C0C0FF,0000FF,0000C0
					Out[y, x] := "B"
				else if Color in FFC0FF,FF00FF,C000C0
					Out[y, x] := "M"
				Else if Color = FFFFFF
					Out[y, x] := "O"
				Else if Color = 000000
					Out[y, x] := "."
			}
		}
	}
	for y, Row in Out
	{
		for x, char in Row
		{
			OutText .= Char
		}
		OutText .= "`n"
	}
	GuiControl, Codel:, GText, %OutText%
}

ReverseGrid(Grid)
{
	Out := []
	for x, Column in Grid
		for y, Value in Column
			Out[y, x] := Value
	return Out
}

PointOutBounds(Point, x1, y1, x2, y2)
{
	if (Point[1] < x1 || Point[1] > x2)
		return true
	if (Point[2] < y1 || Point[2] > y2)
		return true
	
	return false
}

Escape::ExitApp


class Piet
{
	__New(FilePath, CodelSize)
	{
		this.ParseFile(FilePath, CodelSize)
		
		this.Stack := []
		this.Point := [1, 1] ; Top left
		this.StdIn := ""
		
		this.CC := 0 ; [LEFT, Right]
		this.DP := 1 ; [Up, RIGHT, Down, Left]
	}
	
	ParseFile(FilePath, CodelSize)
	{
		pBitmap := Gdip_CreateBitmapFromFile(sFile)
		Gdip_GetDimensions(pBitmap, w, h)
		this.Width := w // CodelSize
		this.Height := h // CodelSize
		
		SetFormat, IntegerFast, H
		
		this.Grid := []
		
		Gdip_LockBits(pBitmap, 0, 0, w, h, Stride, Scan, BitmapData)
		Loop, % this.Width
		{
			x := A_Index
			Loop, % this.Height
			{
				y := A_Index
				ARGB := Gdip_GetLockBitPixel(Scan, (x-1) * CodelSize, (y-1) * CodelSize, Stride)
				this.Grid[x, y] := SubStr(ARGB, -5) ; Last 6 characters of the 0xARGB string (the RGB)
			}
		}
		Gdip_UnlockBits(pBitmap, BitmapData)
		
		SetFormat, IntegerFast, D
		
		Gdip_DisposeImage(pBitmap)
		
		return [this.Width, this.Height]
	}
	
	StdOut(String)
	{
		ConOut := FileOpen("CONOUT$", "w")
		ConOut.Write(String), ConOut.__Handle
		return ConOut
	}
	
	GetStdIn()
	{
		this.StdOut("`n>>> ")
		ConIn := FileOpen("CONIN$", "r")
		this.StdIn .= ConIn.ReadLine()
		this.StdOut("`n")
		return ConIn
	}
	
	Step()
	{ ; TODO
		Codel := new Piet.Codel(this.Point[1], this.Point[2], this.Grid)
	}
	
	NOP()
	{
		return
	}
	PUSH()
	{
		return this.Stack.Insert(this.Codel.Size)
	}
	POP()
	{
		return this.Stack.Remove()
	}
	; ---
	ADD()
	{
		return this.Stack.Insert(this.Stack.Remove() + this.Stack.Remove())
	}
	SUB()
	{
		Subtrahend := this.Stack.Remove()
		Minuend := this.Stack.Remove()
		return this.Stack.Insert(Minuend - Subtrahend)
	}
	MUL()
	{
		return this.Stack.Insert(this.Stack.Remove() * this.Stack.Remove())
	}
	; ---
	DIV()
	{
		Divisor := this.Stack.Remove()
		Dividend := this.Stack.Remove()
		return this.Stack.Insert(Dividend // Divisor)
	}
	MOD()
	{
		Divisor := this.Stack.Remove()
		Dividend := this.Stack.Remove()
		return this.Stack.Insert(Mod(Dividend, Divisor))
	}
	NOT()
	{
		return this.Stack.Insert(!this.Stack.Remove())
	}
	; ---
	GRTR()
	{
		First := this.Stack.Remove()
		Second := this.Stack.Remove()
		return this.Stack.Insert(Second > First)
	}
	PTR()
	{
		this.RotateDP(this.Stack.Remove())
	}
	SWCH()
	{
		this.ToggleCC(this.Stack.Remove())
	}
	; ---
	DUP()
	{
		this.Stack.Insert(this.Stack[this.Stack.MaxIndex()])
	}
	ROLL()
	{
		Rolls := this.Stack.Remove()
		Depth := this.Stack.Remove()
		
		if !Rolls ; Don't roll
			return
		
		if Depth < 2 ; 1 depth does nothing, 0 depth is nothing, negative depth is invalid
			return
		
		DepthPos := this.Stack.MaxIndex() - Depth + 1
		if (Rolls > 0)
			Loop, % Rolls
				this.Stack.Insert(DepthPos, this.Stack.Remove()) ; Take out an item at top and put it at depth
		else
			Loop, % Abs(Rolls)
				this.Stack.Insert(this.Stack.Remove(DepthPos)) ; Take out an item at depth and put it on top
	}
	INN()
	{
		if !this.StdIn
			this.GetStdIn()
		
		if !RegExMatch(this.StdIn, "s)^\s*(\d+)\s*(.*)$", Match)
			return
		this.StdIn := Match2
		return this.Stack.Insert(Match1)
	}
	; ---
	INC()
	{
		if !this.StdIn
			this.GetStdIn()
		
		Char := Asc(SubStr(this.StdIn, 1, 1))
		this.StdIn := SubStr(this.StdIn, 2)
		
		return this.StdIn
	}
	OUTN()
	{
		Num := this.Stack.Remove()
		this.StdOut(" " Num " ")
		return Num
	}
	OUTC()
	{
		Char := Chr(this.Stack.Remove())
		this.StdOut(Char)
		return Char
	}
	
	class Codel
	{
		__New(x, y, Grid)
		{
			this.Color := Grid[x, y]
			Flood := [[x, y]]
			
			i := 0
			this.Grid[x, y] := ++i ; Not sure why I use i for these values instead of true
			
			while Pos := Flood.Remove()
			{
				x := Pos[1], y := Pos[2]
				
				for each, Dir in [[1, 0], [-1, 0], [0, 1], [0, -1]]
				{
					nx := x+Dir[1], ny := y+Dir[2]
					if (Grid[nx, ny] == this.Color && !this.Grid[nx, ny])
						Flood.Insert([nx, ny]), this.Grid[nx, ny] := ++i
				}
			}
			
			this.Count := i
		}
		
		GetCorner(DP, CC)
		{ ; TODO
			if DP == 1 ; Up
			{
				
			}
		}
		
		GetHCorner(Left, Top)
		{ ; TO SCRAP
			for x in this.Grid
				if Left ; If leftmost, break immediately
					break
			for y in Codel[x]
				if Top ; If topmost, break immediately (top is lower on Y axis)
					break
			return [x, y]
		}
		
		GetVCorner(Codel, Top, Left)
		{ ; TO SCRAP
			Codel := Codel.Clone()
			Codel.Remove("Color")
			Codel.Remove("Count")
			Codel := ReverseGrid(Codel)
			
			for y in Codel
				if Top
					break
			for x in Codel[y]
				if Left
					break
			return [x, y]
		}
	}
}