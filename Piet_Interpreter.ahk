#NoEnv
SetBatchLines, -1

#Include Lib\Gdip_All.ahk

DllCall("AllocConsole")

;New File; Start gdi+
If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}
OnExit, ExitSub

; Colors (and operations) are organized in a horizontal grid
;    R   Y   G   C   B   M 
; L|1,1|2,1|3,1|4,1|5,1|6,1
; M|1,2|2,2|3,2|4,2|5,2|6,2
; D|1,3|2,3|3,3|4,3|5,3|6,3

;CodelSize := 1
if %1%
	sFile = %1%
else
	FileSelectFile, sFile

MyPiet := new Piet(sFile)
StdOut := MyPiet.Execute()
MsgBox, % StdOut
ExitApp
return

ExitSub:
Gdip_Shutdown(pToken)
ExitApp

class Piet
{
	__New(FilePath, CodelSize=0)
	{
		this.Stack := []
		this.Point := [1, 1] ; Top left
		this.StdIn := "" ; Possible other name: Buffer
		this.CodelSize := CodelSize
		this.CurrentCodel := Object()
		
		this.CC := 0 ; [LEFT, Right]
		this.DP := 1 ; [Up, RIGHT, Down, Left]
		
		; This table is horizontal
		this.Operations := [[this.NOP, this.PUSH, this.POP]
		,[this.ADD, this.SUB, this.MUL]
		,[this.DIV, this.MOD, this.NOT]
		,[this.GRTR, this.PTR, this.SWCH]
		,[this.DUP, this.ROLL, this.INN]
		,[this.INC, this.OUTN, this.OUTC]]
		
		this.StdOut("Loading`n")
		this.ParseFile(FilePath)
		this.StdOut("Codel size: " this.CodelSize "`n")
		this.StdOut("Loaded`n`n")
		
		return this
	}
	
	ParseFile(FilePath)
	{
		this.Grid := []
		
		pBitmap := Gdip_CreateBitmapFromFile(FilePath)
		Gdip_GetDimensions(pBitmap, w, h)
		Gdip_LockBits(pBitmap, 0, 0, w, h, Stride, Scan, BitmapData)
		
		if !this.CodelSize
		{
			a := this.GetCodelSize(0, w, h, Scan, Stride)
			b := this.GetCodelSize(1, w, h, Scan, Stride)
			this.CodelSize := a < b ? a : b
		}
		
		this.Width := w // this.CodelSize
		this.Height := h // this.CodelSize
		
		SetFormat, IntegerFast, H ; Hex
		Loop, % this.Width
		{
			x := A_Index
			Loop, % this.Height
			{
				y := A_Index
				ARGB := Gdip_GetLockBitPixel(Scan, (x-1) * this.CodelSize, (y-1) * this.CodelSize, Stride)
				this.Grid[x, y] := SubStr(ARGB, -5) ; Last 6 characters of the 0xARGB string (the RGB)
			}
		}
		SetFormat, IntegerFast, D ; Dec
		
		Gdip_UnlockBits(pBitmap, BitmapData)
		Gdip_DisposeImage(pBitmap)
		
		this.CurrentCodel := new Piet.Codel(this.Point[1], this.Point[2], this.Grid)
		
		return [this.Width, this.Height]
	}
	
	GetCodelSize(i, w, h, Scan, Stride)
	{ ; TODO: Make it do both directions in one call, and get the GCF of all sizes
		; "i" is whether to look vertically or horizontally
		
		CodelSize := w ; I assume codel size can't be larger than the width
		
		; We start with the largest possible codel size so we won't accidentally set codel size to 0
		Count := CodelSize
		
		Loop, % i ? h : w
		{
			i ? (y := A_Index - 1) : (x := A_Index - 1)
			
			; We want to start a new block the first time we loop
			; So we set the current block color to -1, which isn't
			; a valid color, and will be immediately replaced as it
			; sees we've entered a block of color that isn't -1
			CurrentBlockColor := -1
			
			Loop, % i ? w : h
			{
				i ? (x := A_Index - 1) : (y := A_Index - 1)
				
				ARGB := Gdip_GetLockBitPixel(Scan, x, y, Stride)
				
				if (ARGB == CurrentBlockColor) ; If we are more of the last block, just add one to the size
					Count++
				else
				{
					; If the size of the previous block was smaller than the current smallest
					; And (when set set the smallest to the last block) if the smallest size is 1, we can't go smaller so return.
					if (Count < CodelSize && (CodelSize := Count) == 1) ; Short circuit trick
						return 1
					
					; We've entered a new block now, so we want to
					; set the current block color and reset the block size to 1
					CurrentBlockColor := ARGB
					Count := 1
				}
			}
			
			; Since we've exited the grid, we can close the block from the end of the grid.
			if (Count < CodelSize && (CodelSize := Count) == 1) ; Short circuit trick
				return 1
		}
		
		return CodelSize
	}
	
	StdOut(String)
	{
		this.OutBuffer .= String
		ConOut := FileOpen("CONOUT$", "w")
		ConOut.Write(String), ConOut.__Handle
		return ConOut
	}
	
	GetStdIn()
	{
		this.StdOut("`n>>> ")
		ConIn := FileOpen("CONIN$", "r")
		Input := ConIn.ReadLine()
		StringReplace, Input, Input, `r,, All
		this.StdIn .= Input
		this.StdOut("`n")
		return ConIn
	}
	
	Execute()
	{
		Try
			Loop
				this.Step()
		return this.OutBuffer
	}
	
	Step()
	{
		
		; I should precompute and cache all codels
		this.CurrentCodel := new Piet.Codel(this.Point[1], this.Point[2], this.Grid)
		;Print(this.Point, "<")
		; Find next blob outside codel. Could be cached perhaps?
		this.ExitCodel()
		;Print("Exited:", this.Point)
		; Now we need to glide across white
		if (this.Grid[this.Point*] == "FFFFFF")
		{ ; If we glide over white, there will be no operation to perform
			this.GlideOverWhite()
		}
		else ; If we've moved onto another color block instead, there will be an operation
		{
			; Get the operations, then execute it
			Operation := this.GetOperation(this.CurrentCodel.Color, this.Grid[this.Point*])
			this.ExecuteOperation(Operation)
		}
	}
	
	GlideOverWhite()
	{
		; Will use Grid, DP, CC, and Point to find the next codel to start from
		Wait := 0
		while (this.Grid[this.Point*] == "FFFFFF")
		{
			; Keep going until we've hit a block
			While (this.Grid[this.Point*] == "FFFFFF")
				this.AddDPToPoint()
			
			; If we're in the clear, break!
			if (this.PointInBounds(this.Point) && this.Grid[this.Point*] != "000000")
				break
			
			; Go back a point
			this.RotateDP(2)
			this.AddDPToPoint()
			this.RotateDP(2)
			
			; Toggle the CC and rotate the DP by 1
			this.ToggleCC()
			this.RotateDP()
			Wait++
			
			if (Wait > 8)
				throw "Program stuck in white"
		}
		
		return this.Point
	}
	
	AddDPToPoint()
	{
		static Map := [[0,-1], [1,0], [0,1], [-1,0]]
		this.Point[1] += Map[this.DP+1, 1]
		this.Point[2] += Map[this.DP+1, 2]
		return this.Point
	}
	
	ExitCodel()
	{ ; Uses CurrentCodel, DP, and CC to see what point (if any) we should exit from
		Wait := 0
		Loop
		{
			this.Point := this.CurrentCodel.Corners[this.DP, this.CC]
			;Print(this.CurrentCodel.Corners)
			;Print(this.CurrentCodel.Corners[this.DP, this.CC], this.DP, this.CC)
			if (Wait > 8)
				throw Exception("Program stuck in block " this.Point[1] "," this.Point[2] ";" this.DP ":" this.CC)
			
			if this.PointInBounds(this.Point)
			{
				if (this.Grid[this.Point*] == "000000")
				{ ; This CC option is a wall, try the other one
					this.ToggleCC()
					this.Point := this.CurrentCodel.Corners[this.DP, this.CC]
					if (this.Grid[this.Point*] == "000000")
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
				this.ToggleCC()
				this.RotateDP()
				Wait++
			}
		}
		
		return this.Point
	}
	
	ExecuteOperation(Operation)
	{
		; Pull the operation from the table of operations
		; then call the method by its function pointer
		; making sure to pass the invisible parameter "this"
		return this.Operations[Operation*].(this)
	}
	
	GetOperation(OldColor, NewColor)
	{
		; This table is horizontal
		static ColorToIndex := {"FFC0C0": [1, 1], "FF0000": [1, 2], "C00000": [1, 3]
		,"FFFFC0": [2, 1], "FFFF00": [2, 2], "C0C000": [2, 3]
		,"C0FFC0": [3, 1], "00FF00": [3, 2], "00C000": [3, 3]
		,"C0FFFF": [4, 1], "00FFFF": [4, 2], "00C0C0": [4, 3]
		,"C0C0FF": [5, 1], "0000FF": [5, 2], "0000C0": [5, 3]
		,"FFC0FF": [6, 1], "FF00FF": [6, 2], "C000C0": [6, 3]}
		
		OldPos := ColorToIndex[OldColor]
		NewPos := ColorToIndex[NewColor].Clone() ; We modify this one, so we have to clone it
		
		if (NewPos[1] < OldPos[1])
			NewPos[1] += 6
		if (NewPos[2] < OldPos[2])
			NewPos[2] += 3
		
		return [NewPos[1]-OldPos[1]+1, NewPos[2]-OldPos[2]+1]
	}
	
	ToggleCC(Times=1)
	{
		Loop, % Times
			this.CC := !this.CC
		return this.CC
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
	
	PointInBounds(Point)
	{
		if (Point[1] < 1 || Point[1] > this.Width)
			return false
		if (Point[2] < 1 || Point[2] > this.Height)
			return false
		
		return true
	}
	
	;{ Operations
	NOP()
	{
		return
	}
	PUSH()
	{
		return this.Stack.Insert(this.CurrentCodel.Count)
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
		
		return this.Stack.Insert(Char)
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
						this.ReverseGrid[ny, nx]  := i
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