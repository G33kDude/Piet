﻿; Start gdi+
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

;InputBox, StdIn,, StdIn

pBitmap := Gdip_CreateBitmapFromFile(sFile)

Gdip_GetDimensions(pBitmap, w, h)

Width := w // CodelSize
Height := h // CodelSize

SetFormat, IntegerFast, H

Grid := []

Gdip_LockBits(pBitmap, 0, 0, w, h, Stride, Scan, BitmapData)

Loop, % Width
{
	x := A_Index
	Loop, % Height
	{
		y := A_Index
		
		ARGB := Gdip_GetLockBitPixel(Scan, (x-1) * CodelSize, (y-1) * CodelSize, Stride)
		
		Grid[x, y] := SubStr(ARGB, -5)
	}
}

Gdip_UnlockBits(pBitmap, BitmapData)

SetFormat, IntegerFast, D

Gdip_DisposeImage(pBitmap)
Gdip_Shutdown(pToken)

Stack := []
CC := 0 ; [LEFT, Right]
DP := 1 ; [Up, RIGHT, Down, Left]

Pixel := [1, 1]

DllCall("AllocConsole")
cStdOut := FileOpen("CONOUT$", "w")

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
	
	if (Op == "0,0")
	{
	}
	else if (Op == "0,1")
	{
		Stack.Insert(Codel.Count)
	}
	else if (Op == "0,2" && Stack.MaxIndex() >= 1)
	{
		Stack.Remove()
	}
	else if (Op == "1,0" && Stack.MaxIndex() >= 2)
	{
		first := Stack.Remove()
		second := Stack.Remove()
		Stack.Insert(second + first)
	}
	else if (Op == "1,1" && Stack.MaxIndex() >= 2)
	{
		subtrahend := Stack.Remove()
		minuend := Stack.Remove()
		Stack.Insert(minuend - subtrahend)
	}
	else if (Op == "1,2" && Stack.MaxIndex() >= 2)
	{
		first := Stack.Remove()
		second := Stack.Remove()
		Stack.Insert(second * first)
	}
	else if (Op == "2,0" && Stack.MaxIndex() >= 2)
	{
		Divisor := Stack.Remove()
		Dividend := Stack.Remove()
		Stack.Insert(Dividend // Divisor) ; Floor division
	}
	else if (Op == "2,1" && Stack.MaxIndex() >= 2)
	{
		Divisor := Stack.Remove()
		Dividend := Stack.Remove()
		Stack.Insert(Mod(Dividend, Divisor)) ; Floor division
	}
	else if (Op == "2,2" && Stack.MaxIndex() >= 1)
	{
		Stack.Insert(!Stack.Remove())
	}
	else if (Op == "3,0" && Stack.MaxIndex() >= 2)
	{
		First := Stack.Remove()
		Second := Stack.Remove()
		Stack.Insert(Second > First)
	}
	else if (Op == "3,1" && Stack.MaxIndex() >= 1)
	{
		DP := RotateDP(DP, Stack.Remove())
	}
	else if (Op == "3,2" && Stack.MaxIndex() >= 1)
	{
		Loop, % Abs(Stack.Remove())
			CC := !CC
	}
	else if (Op == "4,0" && Stack.MaxIndex() >= 1)
	{
		Stack.Insert(Stack[Stack.MaxIndex()])
	}
	else if (Op == "4,1" && Stack.MaxIndex() >= 2)
	{
		Roll := []
		Rolls := Stack.Remove()
		Depth := Stack.Remove()
		
		
		Max := Stack.MaxIndex()
		if (Rolls != 0 && Depth > 0 && Depth <= Max)
		{
			DepthPos := Max - Depth + 1
			if (Rolls > 0)
				Loop, % Rolls
					Stack.Insert(DepthPos, Stack.Remove())
			else
				Loop, % Abs(Rolls)
					Stack.Insert(Stack.Remove(DepthPos))
		}
		
	}
	else if (Op == "4,2")
	{
		if !StdIn
			MsgBox, outta stdin
		
		if (RegExMatch(StdIn, "^\-?\d+", Match))
		{
			StdIn := SubStr(StdIn, StrLen(Match)+1)
			Stack.Insert(Match)
		}
	}
	else if (Op == "5,0")
	{
		if !StdIn
		{
			cStdOut.Write("`n>>> "), cStdOut.__Handle
			
			cStdIn := FileOpen("CONIN$", "r")
			StdIn .= cStdIn.ReadLine()
			
			cStdOut.Write("`n"), cStdOut.__Handle
		}
		
		Stack.Insert(Asc(SubStr(StdIn, 1, 1)))
		StdIn := SubStr(StdIn, 2)
	}
	else if (Op == "5,1" && Stack.MaxIndex() >= 1)
	{
		Num := Stack.Remove()
		StdOut .= " " Num " "
		cStdOut.Write(" " Num " "), cStdOut.__Handle
	}
	else if (Op == "5,2" && Stack.MaxIndex() >= 1)
	{
		Num := Stack.Remove()
		Chr := Chr(Num)
		
		StdOut .= Chr
		cStdOut.Write(Chr), cStdOut.__Handle
	}
	Else
	{
		MsgBox, % Op
	}
	
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
				Out[y, x] := "♥"
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

GetCodel(x, y, Grid)
{
	Color := Grid[x, y]
	Stack := [[x, y]]
	Out := {"Color": Color}
	
	i := 0
	Out[x, y] := ++i
	
	while (Pos := Stack.Remove(1))
	{
		x := Pos[1], y := Pos[2]
		
		if (Grid[x+1, y] == Color && !Out[x+1, y])
			Stack.Insert([x+1, y]), Out[x+1, y] := ++i
		if (Grid[x-1, y] == Color && !Out[x-1, y])
			Stack.Insert([x-1, y]), Out[x-1, y] := ++i
		if (Grid[x, y+1] == Color && !Out[x, y+1])
			Stack.Insert([x, y+1]), Out[x, y+1] := ++i
		if (Grid[x, y-1] == Color && !Out[x, y-1])
			Stack.Insert([x, y-1]), Out[x, y-1] := ++i
	}
	
	Out["Count"] := i
	return Out
}

GetHCorner(Codel, Left, Top)
{
	Codel := Codel.Clone()
	Codel.Remove("Color")
	Codel.Remove("Count")
	for x in Codel
		if Left ; If leftmost, break immediately
			break
	for y in Codel[x]
		if Top ; If topmost, break immediately (top is lower on Y axis)
			break
	return [x, y]
}

GetVCorner(Codel, Top, Left)
{
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