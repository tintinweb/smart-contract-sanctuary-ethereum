/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Knjiznica {
    struct Knjiga {
        uint index;
        string naslov;
        string avtor;
        string ISBN;
        uint8 izposojena;
        address trenutni_izposojevalec;
        uint cas_vrnitve;
    }

    struct Clan{
        string Ime;
        string Priimek;
    }
    uint stKnjig=0;
    mapping(address => Clan) clani;
    Knjiga[] knjige;

    constructor() {
        NovaKnjiga("Sapiens: A Brief History of Humankind","Yuval Noah Harari","xx1");
        NovaKnjiga("Homo Deus: A Brief History of Tomorrow","Yuval Noah Harari","xx2");
        NovaKnjiga("The 5AM Club","Robin Sharma","xx3");
        NovaKnjiga("Wuthering Heights","Emily Bronte","xx4");
    }

    event DodanaKnjiga(uint id);
    function NovaKnjiga(string memory  naslov, string memory avtor, string memory ISBN) public {
        Knjiga memory knjiga;
        knjiga.naslov=naslov;
        knjiga.avtor= avtor;
        knjiga.ISBN=ISBN;
        knjiga.index=knjige.length;
        knjiga.izposojena=0;
        knjige.push(knjiga);
        emit DodanaKnjiga(knjiga.index);
    }

    function dodajTriTedne(uint epochZacetni) private pure returns (uint ){
        return epochZacetni + 1814400;
    }

    function dodajTriDni(uint epochZacetni)private pure returns (uint ){
        return epochZacetni + 259200;
    }
    event NovaIzposoja(uint knjiga_id);
    function IzposodiKnjigo(uint knjiga_id) public returns (string memory) {
        uint unixEpochIzposoje = block.timestamp;
        Knjiga memory knjiga=knjige[knjiga_id];
        if(knjiga.izposojena > 0){
            revert();
        }
        else{
            knjiga.izposojena=1;
            knjiga.trenutni_izposojevalec=msg.sender;
            knjiga.cas_vrnitve=dodajTriTedne(unixEpochIzposoje);
            knjige[knjiga_id]=knjiga;
            emit NovaIzposoja(knjiga_id);
            return string(abi.encodePacked("Izposodili ste si knjigo: ", knjiga.naslov, "Datum vrnitve: ", knjiga.cas_vrnitve));
        }
    }

    event VrnitevKnjige(uint knjiga_id);
    function VrniKnjigo(uint knjiga_id) public returns (string memory) {
        Knjiga memory knjiga=knjige[knjiga_id];
        if(msg.sender != knjiga.trenutni_izposojevalec){
           revert();
        }
        else{
            knjiga.izposojena=0;
            knjiga.trenutni_izposojevalec=address(0); // 0x0 naslov se smatra kot nobeden
            knjiga.cas_vrnitve=0;
            knjige[knjiga_id]=knjiga;
            emit VrnitevKnjige(knjiga_id);
            return "Knjiga je bils uspesno vrnjena.";
        }
    }

    function KdoIzposoja(uint knjiga_id) public view returns (uint8,address) {
        return (
            knjige[knjiga_id].izposojena,
            knjige[knjiga_id].trenutni_izposojevalec
        );
    }
    event NovRegistriran(address,string,string);
    function RegistrirajClan(string memory ime, string memory priimek) public {
        Clan memory nov_clan;
        nov_clan.Ime=ime;
        nov_clan.Priimek=priimek;
        clani[msg.sender]=nov_clan;
        emit NovRegistriran(msg.sender,ime,priimek);
    }

    function PodatkiOclanu(address clan_id) public view returns (string memory, string memory){
        return (
            clani[clan_id].Ime,
            clani[clan_id].Priimek
        );
    }

    function IsciPoISBN(string memory isbn) public view returns (Knjiga memory){
        
        for (uint i=0; i < knjige.length; i++) {
            string memory book_isbn=knjige[i].ISBN;
            if(StrCompare(isbn,book_isbn)){
                return knjige[i];
            }
         }
         Knjiga memory k;
         return k;
    }

    function IsciPoNaslovu(string memory naslov) public view returns (Knjiga memory){
        
        for (uint i=0; i < knjige.length; i++) {
            string memory book_naslov=knjige[i].naslov;
            if(StrCompare(book_naslov,naslov)){
                return knjige[i];
            }
         }
         Knjiga memory k;
         return k;
    }

    function ISciPoIndex(uint index)public view returns (Knjiga memory){
        return knjige[index];
    }

    function SteviloKnjigZISBN(string memory ISBN)public view returns (uint){
        uint k=0;
        for (uint i=0; i < knjige.length; i++) {
                    string memory book_ISBN=knjige[i].ISBN;
                    if(StrCompare(book_ISBN,ISBN)){
                        k=k+1;
                    }
                }
        return k;
    }
    event PodaljsanjeKnjige(uint index);
    function PodaljsajKnjigo(uint index) public returns (string memory){
        if(knjige[index].izposojena > 0 && knjige[index].izposojena<4 && msg.sender ==knjige[index].trenutni_izposojevalec){     
            knjige[index].izposojena+=1;
            knjige[index].cas_vrnitve=dodajTriDni(knjige[index].cas_vrnitve);
            emit PodaljsanjeKnjige(index);
            return "Knjiga podaljsana";
        }
        else{
            revert();
        }
    }

    function StrCompare(string memory one, string memory two) private pure returns ( bool){
        return keccak256(abi.encodePacked(one))==keccak256(abi.encodePacked(two)); 
    }
}