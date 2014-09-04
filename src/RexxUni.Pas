library RexxUni;

{$CDecl+,OrgName+,I-,S-,Delphi+,Use32+}

Uses OS2Base, OS2Def, Rexx;

{$LINKER
  DESCRIPTION	"REXXUNI 2.0 - UNICODE API for REXX (c) 2001,02 by Max Alekseyev"
  DATA MULTIPLE NONSHARED

  EXPORTS
    UNIQUERYCP	  = UniQueryCp
    UNICPNAME	  = UniCpName
    UNIXLAT	  = UniXlat
    UNILOADFUNCS  = UniLoadFuncs
    UNIDROPFUNCS  = UniDropFuncs
}

function UniMapCpToUcsCp(ulCodePage:ulong;var ucsCodePage;size:ulong):ulong; external 'UCONV' name 'UniMapCpToUcsCp';
function UniCreateUconvObject(var cpname, UconvObject):ulong; external 'UCONV' name 'UniCreateUconvObject';
function UniUconvFromUcs(UconvObject:pointer;var src, ssize, dst, dsize, n):ulong; external 'UCONV' name 'UniUconvFromUcs';
function UniUconvToUcs(UconvObject:pointer;var src, ssize, dst, dsize, n):ulong; external 'UCONV' name 'UniUconvToUcs';
function UniFreeUconvObject(UconvObject:pointer):ulong; external 'UCONV' name 'UniFreeUconvObject';
//Undocumented useless function
//function UniQueryUconvCp(UconvObject:pointer;var p, q):ulong; external 'UCONV' name 'UniQueryUconvCp';

Const
  FunctionTable : Array[1..5] of pChar
		= ('UniQueryCp','UniCpName','UniXlat','UniLoadFuncs','UniDropFuncs');
  DefaultStrLen = 256;			 // default length of RxString

type UniChar=SmallWord;

// Load/Drop functions

Function UniLoadFuncs ( FuncName  : PChar;
			ArgC	  : ULong;
			Args	  : pRxString;
			QueueName : pChar;
			Var Ret   : RxString ) : ULong; export;
var j: integer;
begin
  Ret.strLength := 0; UniLoadFuncs := 40;
  If ArgC = 0 then		     { Do not allow parameters }
  begin
    For j := Low(FunctionTable) to High(FunctionTable) do
	RexxRegisterFunctionDLL(FunctionTable[j], 'REXXUNI', FunctionTable[j]);
    UniLoadFuncs := 0;
  end;
end;

Function UniDropFuncs ( FuncName  : PChar;
			ArgC	  : ULong;
			Args	  : pRxString;
			QueueName : pChar;
			Var Ret   : RxString ) : ULong; export;
var j: integer;
begin
  Ret.strLength := 0; UniDropFuncs := 40;
  If ArgC = 0 then		    { Do not allow parameters }
  begin
    For j := Low(FunctionTable) to High(FunctionTable) do
	RexxDeregisterFunction(FunctionTable[j]);
    UniDropFuncs := 0;
  end;
end;

// Internal functions

function CreateUconvObjCp(cp:integer):pointer;
var unistr:array[byte] of UniChar;
begin
  if (UniMapCpToUcsCp(cp,unistr,256)<>0) or (UniCreateUconvObject(unistr,Result)<>0) then Result := nil;
end;

function CreateUconvObjName(rxstr:pRxString):pointer;
var unistr:array[byte] of UniChar;
    convobj :pointer;
    q :^UniChar;
    v, Code :integer;
begin
    Result := nil;
    convobj := CreateUconvObjCp(0);
//    if convobj = nil Then Exit;
    q := @unistr; v := 256;
    Code := UniUconvToUcs(convobj,rxstr^.strptr,rxstr^.strLength,q,v,Code);
    q^ := 0;
    UniFreeUconvObject(convobj);
    if (Code=0) and (UniCreateUconvObject(unistr,convobj)=0) Then Result := convobj;
end;

procedure FreeUconvObj(convobj:pointer); inline;
begin
  if convobj<>nil Then UniFreeUconvObject(convobj);
end;

function SystemCp:ULong;
var ArCP,PcCP:ULong;
begin
  DosQueryCp(4,ArCP,PcCP);
  SystemCp := ArCP;
end;

///////////////////////////////////////////////////////////////////////

// Other interface functions

function UniQueryCp( FuncName  : PChar;
		  ArgC	    : ULong;
		  Args	    : pRxString;
		  QueueName : pChar;
		  Var Ret   : RxString ) : ULong; export;
var s:string;
    cp: integer;
    convobj:pointer;
begin
  Ret.strLength:=1; Ret.strptr^ := '0';
  UniQueryCp := 0;

  case ArgC of
  0: cp := SystemCp;
  1:
  begin
    convobj := CreateUconvObjName(Args);
    if convobj<>nil Then
    begin
// Since IBM doesn't provide a legal way to query CP number by its name
// we're forced to use a "dirty" trick
      asm
	 mov eax, convobj
	 mov eax, [eax]
	 mov eax, [eax+$C]
//	   movzx eax, word ptr [eax+$C]
	 mov cp, eax
      end;
      UniFreeUconvObject(convobj);
    end else cp := 0;
  end;
  else begin UniQueryCp := 40; Exit; end;
  end;

  str(cp,s);
  with Ret do
  begin
    strLength := length(s);
    Move(s[1],strptr^,strLength);
  end;
end;

///////////////////////////////////////////////////////////////////

function UniCpName(  FuncName  : PChar;
		  ArgC	    : ULong;
		  Args	    : pRxString;
		  QueueName : pChar;
		  Var Ret   : RxString ) : ULong; export;
var unistr:array[byte] of UniChar;
    cp, Code, u, v : integer;
    s: string;
    convobj, p, q: pointer;
begin
  Ret.strLength:=0;
  if ArgC>1 Then begin UniCpName := 40; Exit; end;

  UniCpName := 0; Code := 0;
  if ArgC=1 Then Val(Args^.strptr, cp, Code) else cp := SystemCp;
  if (Code<>0) or (UniMapCpToUcsCp(cp,s[1],127)<>0)		   // Get a uniName to @s[1]
	       or (UniCreateUconvObject(s[1],convobj)<>0)	   // and check if it's supported
	       then Exit;
  UniFreeUconvObject(convobj);
  convobj := CreateUconvObjCp(0);
{ if convobj = nil Then 		  // Impossible!
  begin
    UniCpName := 40;
    Exit;
  end; }
  s[0]:=#255; u := Pos(#0#0,s) shr 1;
  p := @s[1]; q := Ret.strptr;
  v := DefaultStrLen;
  Code := UniUconvFromUcs(convobj,p,u,q,v,Code);
  UniFreeUconvObject(convobj);
  if Code=0 Then Ret.strLength := DefaultStrLen - v;
end;

//////////////////////////////////////////////////////////////////////////

function UniXlat(  FuncName  : PChar;
		  ArgC	    : ULong;
		  Args	    : pRxString;
		  QueueName : pChar;
		  Var Ret   : RxString ) : ULong; export;
var unistr:array[byte] of UniChar;
    cp1, cp2, Code, u, v : ULong;
    convobj1, convobj2, p, q, r : pointer;
begin
  Ret.strLength:=0; UniXlat := 40;
  if (ArgC<2) or (ArgC>3) Then Exit;

    Code := 0;
    Inc(Args);
    if Args^.strLength=0 Then cp1:=SystemCp else Val(Args^.strptr,cp1,Code);
    If Code=0 Then convobj1 := CreateUconvObjCp(cp1)
	      Else convobj1 := CreateUconvObjName(Args);

    Code := 0;
    Inc(Args);
    if (ArgC<3) or (Args^.strLength=0) Then cp2:=SystemCp else Val(Args^.strptr,cp2,Code);
    If Code=0 Then convobj2 := CreateUconvObjCp(cp2)
	      Else convobj2 := CreateUconvObjName(Args);

    Dec(Args);
    Dec(Args);

    if (convobj1<>nil) and (convobj2<>nil) Then
    begin
      u := Args^.strLength; v := u;
      GetMem(r,2*u); p := r;
      Code := UniUconvToUcs(convobj2,Args^.strptr,Args^.strLength,p,v,Code);
      dec(u,v); 		       // u = number of UniChars in UniString r^
      if Code=0 Then with Ret do
      begin
	v := u * 3;		       // buffer should be large enough to 3-byte symbols
	if v>DefaultStrLen Then GetMem(strptr,v);
	strLength := v;
	p := r; q := strptr;
	Code := UniUconvFromUcs(convobj1,p,u,q,v,Code);
	dec(strLength,v);
      end;
      if Code = 0 Then UniXlat := 0;
      FreeMem(r);
    end;
    FreeUconvObj(convobj1);
    FreeUconvObj(convobj2);
end;

initialization
end.
