
SHELL=/QOpenSys/usr/bin/qsh
LIBRARY=GITCM
LIBLIST=$(LIBRARY)
SYSTEM_PARMS=-s

all: gitcm.bnddir gitint.cmd gitbrn.cmd gitbrg.cmd gitcmtmrg.cmd gitdff.cmd gitlog.cmd

gitcm.bnddir: utils.entry objects.entry object.entry members.entry git.entry

utils.entry: utils.srvpgm
utils.srvpgm: utils.sqlrpgmod

object.entry: object.srvpgm
object.srvpgm: object.rpgmod

objects.entry: objects.srvpgm
objects.srvpgm: objects.rpgmod

members.entry: members.srvpgm
members.srvpgm: members.rpgmod

git.entry: git.srvpgm
git.srvpgm: git.rpgmod

gitint.cmd: gitint.rpgle
gitbrn.cmd: gitbrn.rpgle
gitbrg.cmd: gitbrg.rpgle
gitcmtmrg.cmd: gitcmtmrg.rpgle
gitdff.cmd: gitdff.rpgle
gitlog.cmd: gitlog.rpgle

gitint.rpgle: gitcm.bnddir
gitbrn.rpgle: gitcm.bnddir
gitbrg.rpgle: gitcm.bnddir
gitcmtmrg.rpgle: gitcm.bnddir
gitdff.rpgle: gitcm.bnddir diffscrn.dspf
gitlog.rpgle: gitcm.bnddir gitdsp.dspf

%.rpgle: qrpglesrc/%.rpgle
	liblist -a $(LIBLIST);\
	system $(SYSTEM_PARMS) "CRTBNDRPG PGM($(LIBRARY)/$*) SRCSTMF('$<') OPTION(*EVENTF) DBGVIEW(*SOURCE) TGTRLS(*CURRENT)"

%.rpgmod: qrpglesrc/%.rpgle
	system $(SYSTEM_PARMS) "CHGATR OBJ('$<') ATR(*CCSID) VALUE(1252)"
	liblist -a $(LIBLIST);\
	system $(SYSTEM_PARMS) "CRTRPGMOD MODULE($(LIBRARY)/$*) SRCSTMF('$<') DBGVIEW(*SOURCE)"

%.sqlrpgmod: qrpglesrc/%.sqlrpgle
	system $(SYSTEM_PARMS) "CHGATR OBJ('$<') ATR(*CCSID) VALUE(1252)"
	liblist -a $(LIBLIST);\
	system $(SYSTEM_PARMS) "CRTSQLRPGI OBJ($(LIBRARY)/$*) SRCSTMF('$<') CLOSQLCSR(*ENDMOD) OPTION(*EVENTF) DBGVIEW(*SOURCE) OBJTYPE(*MODULE)"

%.srvpgm:
	-system $(SYSTEM_PARMS) "DLTOBJ OBJ($(LIBRARY)/$*) OBJTYPE(*SRVPGM)"
	liblist -a $(LIBLIST);\
	system $(SYSTEM_PARMS) "CRTSRVPGM SRVPGM($(LIBRARY)/$*) MODULE(*SRVPGM) EXPORT(*ALL)"

%.dspf: qddssrc/%.dspf
	-system -q "CRTSRCPF FILE($(LIBRARY)/QSOURCE) RCDLEN(112)"
	system $(SYSTEM_PARMS) "CPYFRMSTMF FROMSTMF('$<') TOMBR('/QSYS.lib/$(LIBRARY).lib/QSOURCE.file/$(notdir $*).mbr') MBROPT(*REPLACE)"
	system $(SYSTEM_PARMS) "CRTDSPF FILE($(LIBRARY)/$*) SRCFILE($(LIBRARY)/QSOURCE) SRCMBR(*FILE)"

%.cmd: qcmdsrc/%.cmd
	-system -q "CRTSRCPF FILE($(LIBRARY)/QSOURCE) RCDLEN(112)"
	system $(SYSTEM_PARMS) "CPYFRMSTMF FROMSTMF('$<') TOMBR('/QSYS.lib/$(LIBRARY).lib/QSOURCE.file/$*.mbr') MBROPT(*REPLACE)"
	system $(SYSTEM_PARMS) "CRTCMD CMD($(LIBRARY)/$*) PGM($(LIBRARY)/$*) SRCFILE($(LIBRARY)/QSOURCE)"

%.bnddir:
	-system -q "CRTBNDDIR BNDDIR($(LIBRARY)/$*)"
	-system -q "ADDBNDDIRE BNDDIR($(LIBRARY)/$*) OBJ($(patsubst %.entry,($(LIBRARY)/% *SRVPGM *IMMED),$^))"

%.entry:
	@echo "Entry: $*"