/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

pragma solidity ^0.8.7;
contract Knjiznica{
	mapping(uint => Stranka) public stranke;
    mapping(uint => Knjiga) public knjige;

    uint strankeCount;
	uint knjigeCount;

     modifier statusKnjige(uint id)
    {   
        require(knjige[id].izposojena == false);
        _;
    }

         modifier niIzposojena(uint id)
    {   
        require(knjige[id].izposojena == true);
        _;
    }

             modifier niPodaljsano(uint id)
    {   
        require(knjige[id].izposojena == true);
        require(knjige[id].podaljsanja < 3);
        _;
    }

    struct Stranka{
        uint stranka_id;
        string ime;
        string priimek;
        string naslov;
        
    }

    struct Knjiga{
        uint knjiga_id;
        string naslov;
        string ISBN;
        string avtor;
        bool izposojena;
        uint datumVrnitve;
        uint trenutniIzposojevalec;
        uint podaljsanja;
    }

        function registerKnjiga(uint id, string memory naslov, string memory ISBN, 
                             string memory avtor, bool izposojena, uint datumVrnitve, uint256 trenutniIzposojevalec, uint podaljsanja) public {
        Knjiga memory newKnjiga;
        newKnjiga.knjiga_id = id;
        newKnjiga.naslov = naslov;
        newKnjiga.ISBN = ISBN;
        newKnjiga.avtor = avtor;
        newKnjiga.izposojena = izposojena;
        newKnjiga.datumVrnitve = datumVrnitve;
         newKnjiga.trenutniIzposojevalec = trenutniIzposojevalec;
        newKnjiga.podaljsanja = podaljsanja;
        knjige[id] = newKnjiga;
        
    }

     constructor () 
    {
        stranke[0] = Stranka(0,"Jaka","Udovic","Trusiceva 00");
        stranke[1] = Stranka(1,"Marko","Kralj","Ulica bratov Novak 21");
        stranke[2] = Stranka(2,"Tilen","Nastran","Trusiceva 00");
        stranke[3] = Stranka(3,"Miha","Sintar","Trusiceva 00");


       knjige[0] = Knjiga(0, "Harry Potter", "123", "JK Rowling", false, 0, 0, 0);
       knjige[1] = Knjiga(1, "Zlati orli", "1234", "Marko Franziskaner", false, 0, 0, 0);
       knjige[2] = Knjiga(2, "Vojna in mir", "12345", "Lev Tolstoj", false, 0, 0, 0);
       knjige[3] = Knjiga(3, "Krst pri savici", "123456", "France Preseren", false, 0, 0, 0);

    }

     function getKnjiga(uint256 id) public view returns (string memory, string memory, string memory, bool, uint, uint){
        Knjiga storage s = knjige[id];
        return (s.naslov,s.avtor,s.ISBN,s.izposojena,s.trenutniIzposojevalec,s.datumVrnitve);
    }

        function registerStranka(uint id, string memory naslov) public {
        Stranka memory newStranka;
        newStranka.stranka_id = id;
        newStranka.naslov = naslov;
        stranke[id] = newStranka;
        
    }

     function getStranka(uint256 id) public view returns (string memory , uint){
        Stranka storage s = stranke[id];
        return (s.naslov,s.stranka_id);
    }


    event eventIzposoja(uint id, string naziv, string avtor, string ISBN, bool izposojena, uint casVrnitve, uint izposojevalec, bool izposojaUspesna);
	function izposojaKnjige(uint p, uint b) public statusKnjige(p) returns(uint result)
		{
            uint i = 1;
            uint counter = 0;
            while(knjige[i].knjiga_id != 0)
            {
                counter++;
                i++;
            }

			for(i = 0; i <= counter; i++)
				{
				uint id = knjige[i].knjiga_id;
               if(id == p)
                {
                    knjige[i].izposojena = true;
                    knjige[i].trenutniIzposojevalec = b;
                    knjige[i].datumVrnitve = block.timestamp + 1814400; 
                    result = knjige[i].knjiga_id;
                    emit eventIzposoja(knjige[i].knjiga_id, knjige[i].naslov, knjige[i].avtor, knjige[i].ISBN, knjige[i].izposojena, knjige[i].datumVrnitve, b, true);
                    return result;
                    
                }


					}
                   
			}
    event eventVracanje(uint id, string naziv, string avtor, string ISBN, bool izposojena, uint casVrnitve);
    function vracanjeKnjige(uint k) public niIzposojena(k) returns(uint result)
		{

             
                    knjige[k].izposojena = false;
                    knjige[k].trenutniIzposojevalec = 0;
                    knjige[k].datumVrnitve = 0; 
                    result = knjige[k].knjiga_id;
                    emit eventVracanje(knjige[k].knjiga_id, knjige[k].naslov, knjige[k].avtor, knjige[k].ISBN, knjige[k].izposojena, knjige[k].datumVrnitve);
                    return result;
                    }

    
    function preverjanjeRazpolozljivosti(string memory k) public view returns(uint )
		{
            uint result = 0;
            uint i = 1;
            uint counter = 0;
            while(knjige[i].knjiga_id != 0)
            {
                counter++;
                i++;
            }

            for(i = 0; i <= counter; i++)
            {

              if(knjige[i].izposojena == false)
                {
                if(keccak256(abi.encodePacked(knjige[i].naslov)) == keccak256(abi.encodePacked(k)))
                    {
                    result = result + 1;
                    
                    }
                }
            }
            return result;
		}

             function iskanjeKnjige(string memory k) public view returns(string memory, string memory, string memory, bool, uint, uint)
		{
            int b = 0;
            uint i = 1;
            uint counter = 0;
            while(knjige[i].knjiga_id != 0)
            {
                counter++;
                i++;
            }

            for(i = 0; i <= counter; i++)
            {       
                if(keccak256(abi.encodePacked(knjige[i].naslov)) == keccak256(abi.encodePacked(k)) || keccak256(abi.encodePacked(knjige[i].ISBN)) == keccak256(abi.encodePacked(k)) || keccak256(abi.encodePacked(knjige[i].avtor)) == keccak256(abi.encodePacked(k)))
                    {
                    b = 1;
                    return (knjige[i].naslov,knjige[i].avtor,knjige[i].ISBN,knjige[i].izposojena,knjige[i].trenutniIzposojevalec,knjige[i].datumVrnitve);
                    }    
            }


            
		}
            event eventPodaljsanje(uint id, uint casVrnitve, uint steviloPodaljsanj, bool podaljsanjeUspesno);

            function podaljsanjeKnjige(uint k) public niPodaljsano(k) returns(uint result)
		{

              if(knjige[k].podaljsanja < 3)
                    {
                    knjige[k].podaljsanja++;
                    knjige[k].datumVrnitve = knjige[k].datumVrnitve + 259200;
                    emit eventPodaljsanje(knjige[k].knjiga_id, knjige[k].datumVrnitve, knjige[k].podaljsanja, true);
                    return result;
                    }
                    else 
                    {
                        emit eventPodaljsanje(knjige[k].knjiga_id, knjige[k].datumVrnitve, knjige[k].podaljsanja, false);
                    }
                
                   
			}
}