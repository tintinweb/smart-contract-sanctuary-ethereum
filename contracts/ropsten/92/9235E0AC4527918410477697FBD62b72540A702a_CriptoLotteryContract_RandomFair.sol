/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract CriptoLotteryContract_RandomFair
{
    address owner;
    uint public oracleResponse;

    constructor()
    {
        owner = msg.sender;
    }

    string public constant credits = "CriptoLottery 1.0, by Luca, Fede e Dario";

    uint8 constant MAX_PLAYERS = 50;
    uint8 constant MIN_PLAYERS = 5;

    bool existsWinner = false;

    // L'intero balance del contratto viene diviso in 4 conti logici
    uint winnerBalance   =0;
    uint adminBalance    =0;
    uint usersBalance    =0;
    
    struct user
    {
        string  name;
        address addr;
        uint256 quote;
        uint256 joinTimeStamp;
    }
    user[] users;
    user[] aux;
    
    user winner;
    uint winnerIndex;

    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DAGLI UTENTI
    //  Questa funzione permette a un utente di iscriversi.
    //  Il minimo che può essere inserito è 1R-ETH, il massimo è 3R-ETH.
    //  Possono iscriversi al massimo 50 utenti.
    //  L'iscrizione è possibile una sola volta all'interno di un round di gioco.
    //  Ogni iscrizione comporta: 
    //      - L'inserimento dell'utente in una apposita struttura dati,
    //      - La produzione di un numero random per la fine del gioco (se si è raggiunto il minimo dei partecipanti)    
    //      - La ripartizione dei bilanci                                        
    //  *****************************************************************************************************
    function subscribe(string memory _name) public payable returns(string memory)
    {
        require(msg.value>=1000000000000000000 , "CHECK MINIMUM AMOUNT");
        require(msg.value<=3000000000000000000 , "CHECK MAXIMUM AMOUNT");
        
        require(users.length<MAX_PLAYERS, "TOO MUCH USERS");
        
        require(!isAddressInList(msg.sender), "ADDRESS ALREADY IN LIST");
        require(!isNameInList(_name), "USER NAME ALREADY IN LIST");

        require(!existsWinner);

        for(uint8 i=0; i<msg.value/1000000000000000000;i++)
        {
            users.push(user(_name, msg.sender, msg.value, block.timestamp));
        }
        usersBalance += msg.value;

        winnerIndex = Random(users.length);
        
        oracleResponse = Random(2);

        if((oracleResponse==1 && users.length>=MIN_PLAYERS) || users.length==MAX_PLAYERS-2)
            {
                existsWinner            = true;
                oracleResponse          = 0;
                winner.name             = users[winnerIndex].name;
                winner.addr             = users[winnerIndex].addr;
                winner.quote            = users[winnerIndex].quote;
                winner.joinTimeStamp    = block.timestamp;

                winnerBalance           = (address(this).balance)*70/100;
                adminBalance            = (address(this).balance-winnerBalance);
                usersBalance            = 0;

                delete users;
            }
        return "success";
    }

    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DAGLI UTENTI
    //  Questa funzione permette a un utente di ritirare la propria iscrizione se non è ancora stato settato
    //  un vincitore.
    //  *****************************************************************************************************
    function unsubscribe() public payable
    {
        require(!existsWinner);
        require(isAddressInList(msg.sender));

        uint8 index;
        for(uint8 i=0; i<users.length;i++)
        {
            if(msg.sender==users[i].addr)
            {    
                index=i;
            }
        }
        uint256 amount = users[index].quote;

        payable(msg.sender).transfer(amount);
        usersBalance-=amount;

        for(uint8 i=0; i<users.length;i++)
        {
            if(users[i].addr!=msg.sender)
            {
                aux.push(users[i]);
            }
        }
        
        delete users;
        users = aux;
        delete aux;
    }


    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DAGLI UTENTI E DALL'AMMINISTRATORE
    //  Questa funzione permette a un utente o all'amministratore di verificare l'esistenza di un vincitore                             
    //  *****************************************************************************************************
    function verifyWinner() public view returns(string memory)
    {   
        if(existsWinner)
            return appendString(appendString("the winner is ",winner.name), addressToString(winner.addr));
        else 
            return("No winners yet");
    }

    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DAGLI UTENTI E DALL'AMMINISTRATORE
    //  Questa funzione permette a un utente o all'amministratore di verificare la lista dei partecipanti                             
    //  *****************************************************************************************************
    function getUsersList() public view returns(string memory)
    {
        string memory res;
        string memory entry;
        
        for(uint8 i=0; i<users.length;i++)
        {
            entry = appendString(users[i].name, addressToString(users[i].addr));
            res = appendString(res, entry);
            res = appendString(res, "\n");
        }
        return res;
    }

    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DAGLI UTENTI
    //  Questa funzione permette a un utente di riscuotere la vincita.
    //  Il vincitore deve essere stato decretato.
    //  L'indirizzo dell'utente che tenta il prelievo deve essere lo stesso di quello che ha vinto.                                     
    //  *****************************************************************************************************
    function payWinner() payable public
    {
        require(existsWinner);
        require(msg.sender==winner.addr, "You are not the winner");
        payable(winner.addr).transfer(winnerBalance);
        
        delete winner;
        winnerBalance = 0;
        existsWinner = false;
    }

    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DAGLI UTENTI O DALL'AMMINISTRATORE
    //  Questa funzione permette a un utente o all'amministratore di verificare il montepremi
    //  *****************************************************************************************************
    function getWinnerBalance() public view returns(uint)
    {
        if(existsWinner)
        {
            return winnerBalance;
        }
        else
        {
            return usersBalance*70/100;
        }
    }

    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DAGLI UTENTI O DALL'AMMINISTRATORE
    //  Questa funzione permette a un utente o all'amministratore di verificare il balance del contratto
    //  *****************************************************************************************************
    function getBalance() public view returns(uint)
    {
        return address(this).balance;
    }

    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DALL'AMMINISTRATORE
    //  Questa funzione permette all'amministratore di verificare il proprio balance
    //  *****************************************************************************************************
    function getAdminBalance() public view returns(uint)
    {
        require(msg.sender==owner, "You are not the admin");
        return adminBalance;
    }

    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DALL'AMMINISTRATORE
    //  Questa funzione permette all'amministratore di verificare il balance accumulato da tutti gli utenti
    //  *****************************************************************************************************
    function getUsersBalance() public view returns(uint)
    {
        require(msg.sender==owner, "You are not the admin");
        return usersBalance;
    }

    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DALL'AMMINISTRATORE
    //  Questa funzione permette all'amministratore di prelevare i fondi a lui destinati
    //  *****************************************************************************************************
    function withdrawAdmin() public payable
    {
        require(msg.sender==owner, "You are not the admin");
        require(adminBalance>0);
        payable(msg.sender).transfer(adminBalance);
        adminBalance = 0;
    }

    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DALL'AMMINISTRATORE
    //  Questa funzione permette all'amministratore di trasferire i fondi del vincitore nel proprio conto
    //  quando questo non ritira la propria vincita entro un certo tempo.
    //  *****************************************************************************************************
    function updateAdminBalance() public
    {
        require(msg.sender==owner, "You are not the admin");
        require(existsWinner);
        require((block.timestamp-winner.joinTimeStamp)>5*60);    
        adminBalance+=winnerBalance;
        
        delete winner;
        winnerBalance=0;
        existsWinner=false;
    }

    //  *****************************************************************************************************
    //  FUNZIONE CHIAMATA DALL'AMMINISTRATORE
    //  Questa funzione permette all'amministratore capire quanto è passato dalla proclamazione del vincitore
    //  Allo scadere di un timeout (5min) può infatti trasferire il credito non reclamato nel suo conto.
    //  *****************************************************************************************************
    function getElapsedTime() public view returns(uint)
    {
        require(msg.sender==owner);
        require(existsWinner);
        return (block.timestamp - winner.joinTimeStamp);
    }

    //  *****************************************************************************************************
    //  FUNZIONI DI LIBRERIA
    //  *****************************************************************************************************
    function isAddressInList(address addr) view private returns(bool)
    {
        for(uint8 i=0; i<users.length;i++){
            if(users[i].addr==addr) return true;}
        return false;
    }

    function isNameInList(string memory name) view private returns(bool)
    {
        for(uint8 i=0; i<users.length;i++){
            if(strcmp(users[i].name,name)) 
                return true;}
            return false;
    }

    function appendString(string memory a, string memory b) private pure returns (string memory) 
    {
        return string(abi.encodePacked(a," ",b));
    }

    function strcmp(string memory str_a, string memory str_b) private pure returns (bool) 
    {
        return (keccak256(abi.encodePacked((str_a))) == keccak256(abi.encodePacked((str_b))));
    }

    function addressToString(address _addr) private pure returns(string memory) 
    {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < 20; i++) 
        {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    function Random(uint number) public view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % number;
    }

}