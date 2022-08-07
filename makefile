
SHELL=/QOpenSys/usr/bin/qsh
LIBRARY=GITCM
LIBLIST=$(LIBRARY)
SYSTEM_PARMS=-s

all: gitcm.bnddir gitint.cmd gitbrn.cmd gitbrg.cmd gitcmtmrg.cmd gitdff.cmd gitlog.cmd gitrst.cmd gitrpo.cmd

gitcm.bnddir: utils.srvpgm objects.srvpgm object.srvpgm members.srvpgm git.srvpgm
utils.srvpgm: utils.sqlrpgmod
object.srvpgm: object.rpgmod
objects.srvpgm: objects.rpgmod
members.srvpgm: members.rpgmod
git.srvpgm: git.rpgmod utils.srvpgm

gitint.cmd: gitint.rpgle
gitbrn.cmd: gitbrn.rpgle
gitbrg.cmd: gitbrg.rpgle
gitcmtmrg.cmd: gitcmtmrg.rpgle
gitdff.cmd: gitdff.rpgle
gitlog.cmd: gitlog.rpgle
gitrst.cmd: gitrst.rpgle
gitrpo.cmd: gitrpo.rpgle

gitint.rpgle: gitcm.bnddir
gitbrn.rpgle: gitcm.bnddir
gitbrg.rpgle: gitcm.bnddir
gitcmtmrg.rpgle: gitcm.bnddir
gitdff.rpgle: gitcm.bnddir diffscrn.dspf
gitlog.rpgle: gitcm.bnddir gitdsp.dspf gitcmtinf.rpgle
gitcmtinf.rpgle: gitcm.bnddir commit.dspf gitdffcmt.rpgle gitrst.cmd
gitdffcmt.rpgle: gitcm.bnddir diffscrn.dspf
gitrpo.rpgle: repo.dspf
gitrst.rpgle: gitcm.bnddir

%.rpgle: qrpglesrc/%.rpgle
	system $(SYSTEM_PARMS) "CHGATR OBJ('$<') ATR(*CCSID) VALUE(1252)"
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
	-system -q "CRTSRCPF FILE($(LIBRARY)/QDDSSRC) RCDLEN(112)"
	system $(SYSTEM_PARMS) "CPYFRMSTMF FROMSTMF('$<') TOMBR('/QSYS.lib/$(LIBRARY).lib/QDDSSRC.file/$(notdir $*).mbr') MBROPT(*REPLACE)"
	system $(SYSTEM_PARMS) "CRTDSPF FILE($(LIBRARY)/$*) SRCFILE($(LIBRARY)/QDDSSRC) SRCMBR(*FILE) OPTION(*EVENTF)"

%.cmd: qcmdsrc/%.cmd
	-system -q "CRTSRCPF FILE($(LIBRARY)/QCMDSRC) RCDLEN(112)"
	system $(SYSTEM_PARMS) "CPYFRMSTMF FROMSTMF('$<') TOMBR('/QSYS.lib/$(LIBRARY).lib/QCMDSRC.file/$*.mbr') MBROPT(*REPLACE)"
	system $(SYSTEM_PARMS) "CRTCMD CMD($(LIBRARY)/$*) PGM($(LIBRARY)/$*) SRCFILE($(LIBRARY)/QCMDSRC)"

%.bnddir:
	-system -q "CRTBNDDIR BNDDIR($(LIBRARY)/$*)"
	-system -q "ADDBNDDIRE BNDDIR($(LIBRARY)/$*) OBJ($(patsubst %.srvpgm,($(LIBRARY)/% *SRVPGM *IMMED),$^))"