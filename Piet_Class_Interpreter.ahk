DllCall("AllocConsole")

;New File; Start gdi+
If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}
OnExit, ExitSub

; Colors are organized in a vertical column
;   L  M  D 
; R 11 21 31
; Y 12 22 32
; G 13 23 33
; C 14 24 34
; B 15 25 35
; M 16 26 36

CodelSize := 1
if %1%
	sFile = %1%
else
	FileSelectFile, sFile

MyPiet := new Piet(sFile, 1)

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
Gdip_Shutdown(pToken)
ExitApp

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
				Out[y, x] := "+"
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

PointInBounds(Point, x1, y1, x2, y2)
{
	if (Point[1] < x1 || Point[1] > x2)
		return false
	if (Point[2] < y1 || Point[2] > y2)
		return false
	
	return true
}

class Piet
{
	__New(FilePath, CodelSize)
	{
		this.ParseFile(FilePath, CodelSize)
		
		this.Stack := []
		this.Point := [1, 1] ; Top left
		this.StdIn := "" ; Possible other name: Buffer
		
		this.CC := 0 ; [LEFT, Right]
		this.DP := 1 ; [Up, RIGHT, Down, Left]
		
		this.Operations := [[this.NOP, this.PUSH, this.POP]
		,[this.ADD, this.SUB, this.MUL]
		,[this.DIV, this.MOD, this.NOT]
		,[this.GRTR, this.PTR, this.SWCH]
		,[this.DUP, this.ROLL, this.INN]
		,[this.INC, this.OUTN, this.OUTC]]
		
		return this.Execute()
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
	
	Execute()
	{
		Try
		{
			Loop
				this.Step()
			MsgBox Stepped
		}
		Catch e
			throw e
		Finally
			return
	}
	
	Step()
	{ ; TODO: Finish this
		
		; I should precompute and cache all codels
		Codel := new Piet.Codel(this.Point[1], this.Point[2], this.Grid)
		
		; Find next blob outside codel. Could be cached perhaps?
		Wait := 0
		Loop
		{
			NextPixel := Codel.Corners[this.DP, this.CC]
			
			if PointInBounds(NextPixel, 1, 1, Width, Height)
			{
				if (Grid[NextPixel*] == "000000")
				{ ; This CC option is a wall, try the other one
					this.ToggleCC()
					NextPixel := Codel.Corners[this.DP, this.CC]
					if (Grid[NextPixel*] == "000000")
					{ ; Both CC options are walls
						this.RotateDP()
						Wait++
					}
					else ; Success, not a wall
						Break
				}
				else ; Success, not a wall
					Break
			}
			else
			{ ; This direction is out of bounds
				this.RotateDP()
				Wait++
			}
			
			if (Wait > 8)
				throw Exception("Program stuck")
		}
		
		; Now we need to glide across white
		
		; Get the operations, then execute it
		Operation := this.GetOperation(Codel.Color, Grid[NextPixel*])
		this.ExecuteOperation(Operation)
	}
	
	ExecuteOperation(Operation)
	{
		; Pull the operation from the table of operations
		; then call the method by its function pointer
		; making sure to pass the invisible parameter "this"
		return this.Operations[Operation].(this)
	}
	
	GetOperation(OldColor, NewColor)
	{
		static ColorToIndex := {"FFC0C0": [1, 1], "FF0000": [2, 1], "C00000": [3, 1]
		,"FFFFC0": [1, 2], "FFFF00": [2, 2], "C0C000": [3, 2]
		,"C0FFC0": [1, 3], "00FF00": [2, 3], "00C000": [3, 3]
		,"C0FFFF": [1, 4], "00FFFF": [2, 4], "00C0C0": [3, 4]
		,"C0C0FF": [1, 5], "0000FF": [2, 5], "0000C0": [3, 5]
		,"FFC0FF": [1, 6], "FF00FF": [2, 6], "C000C0": [3, 6]}
		
		OldPos := ColorToIndex[OldColor].Clone()
		NewPos := ColorToIndex[NewColor].Clone()
		
		if (NewPos[1] < OldPos[1])
			NewPos[1] += 3
		if (NewPos[2] < OldPos[2])
			NewPos[2] += 6
		
		return [NewPos[1] - OldPos[1] + 1, NewPos[2] - OldPos[2] + 1)
	}
	
	ToggleCC()
	{
		return this.CC := !this.CC
	}
	
	RotateDP(n=1)
	{ ; TODO: Elegant this
		this.DP += n
		While this.DP > 3
			this.DP -= 4
		While this.DP < 0
			this.DP += 4
		return this.DP
	}
	
	;{ Operations
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
	;}
	
	class Codel
	{
		__New(x, y, Grid)
		{
			this.Color := Grid[x, y]
			Flood := [[x, y]]
			
			i := 0
			this.Grid[x, y] := ++i ; Not sure why I use i for these values instead of true
			this.ReverseGrid[y, x] := i
			
			while Pos := Flood.Remove()
			{
				x := Pos[1], y := Pos[2]
				
				for each, Dir in [[1, 0], [-1, 0], [0, 1], [0, -1]]
				{
					nx := x+Dir[1], ny := y+Dir[2]
					if (Grid[nx, ny] == this.Color && !this.Grid[nx, ny])
					{
						Flood.Insert([nx, ny])
						this.Grid[nx, ny] := ++i
						this.ReverseGrid[nx, ny]  := i
					}
				}
			}
			
			this.Count := i
			
			this.Corners := [] ; Point := this.Corners[DP, CC]
			
			; These two methods work on two principles
			; A) For loops don't delete their iterator once exiting the loop
			; B) Arrays are always looped through numerically lowest to highest
			this.CalculateHCorners()
			this.CalculateVCorners()
		}
		
		CalculateHCorners()
		{
			Flag := True
			for x in this.Grid
			{
				if Flag
				{
					for y in this.Grid[x]
						if Flag
							Flag := False, this.Corners[3, 1] := [x-1, y] ; Left Top (DP 3 CC 1)
					this.Corners[3, 0] := [x-1, y] ; Left Bottom (DP 3 CC 0)
				}
			}
			
			Flag := True
			for y in this.Grid[x]
				if Flag
					Flag := False, this.Corners[1, 0] := [x+1, y] ; Right Top (DP 1 CC 0)
			this.Corners[1, 1] := [x+1, y] ; Right Bottom (DP 1 CC 1)
		}
		
		CalculateVCorners()
		{
			Flag := True
			for y in this.ReverseGrid
			{
				if Flag
				{
					for x in this.ReverseGrid[y]
						if Flag
							Flag := False, this.Corners[0, 0] := [x, y-1] ; Top left (DP 0 CC 0)
					this.Corners[0, 1] := [x, y-1] ; Top Right (DP 0 CC 1)
				}
			}
			
			Flag := True
			for x in this.ReverseGrid[y]
				if Flag
					Flag := False, this.Corners[2, 1] := [x, y+1] ; Bottom Left (DP 2 CC 1)
			this.Corners[2, 0] := [x, y+1] ; Bottom Right (DP 2 CC 0)
		}
	}
}

Escape::ExitApp