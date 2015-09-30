# CouchPotato_QPKG
CouchPotato Server qpkg for QNAP

Steps required to build the package on a QNAP TVS:

    git clone https://github.com/eXodus1440/CouchPotato_QPKG.git CouchPotato
    cd CouchPotato/shared

    git clone https://github.com/RuudBurger/CouchPotatoServer.git 
    mv CouchPotatoServer/* CouchPotatoServer/.* .
    rm -rf CouchPotatoServer

    cd ..
    qbuild --exclude solaris --exclude *.cmd
