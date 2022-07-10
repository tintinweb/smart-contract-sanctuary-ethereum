/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

contract Ownable {
    address public _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Hindi ka may-ari ng contract na ito");
        _;
    }
    modifier notOwner() {
        require(msg.sender != _owner, "This function cannot be executed by owner");
        _;
    }

    constructor(){
        _owner = msg.sender;
    }
}

contract OwnerPayable {
    address payable public owner;

    constructor(){
        owner = payable(msg.sender);
    }

    modifier costs(uint _amount) {
        require(msg.value > 0, "Wala kang pinadalang Ether");
        require(msg.value >= _amount, string.concat("Kulang ang Ether mo: ", utils.toString(_amount), " wei ang kailangan, ", utils.toString(msg.value), " lang ang binigay"));
        _;
    }
}

library utils {
    // https://ethereum.stackexchange.com/a/113327
    function stringsEquals(string memory s1, string memory s2) internal pure returns (bool) {
        bytes memory b1 = bytes(s1);
        bytes memory b2 = bytes(s2);
        uint256 l1 = b1.length;
        if (l1 != b2.length) return false;
        for (uint256 i=0; i<l1; i++) {
            if (b1[i] != b2[i]) return false;
        }
        return true;
    }

    function stringLen(string memory input) internal pure returns (uint256) {
        bytes memory temp = bytes(input);
        return temp.length;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Copied from OpenZeppelin Contracts (MIT) - 3dac7bb
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

        // The MIT License (MIT)
        // 
        // Copyright (c) 2016-2022 zOS Global Limited and contributors
        // 
        // Permission is hereby granted, free of charge, to any person obtaining
        // a copy of this software and associated documentation files (the
        // "Software"), to deal in the Software without restriction, including
        // without limitation the rights to use, copy, modify, merge, publish,
        // distribute, sublicense, and/or sell copies of the Software, and to
        // permit persons to whom the Software is furnished to do so, subject to
        // the following conditions:
        // 
        // The above copyright notice and this permission notice shall be included
        // in all copies or substantial portions of the Software.
        // 
        // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
        // IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
        // CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
        // TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
        // SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

interface IWord {
    function addWord(string memory _word) external;
    function wordCount() external view returns (uint256);
    function listWords() external view returns (string[] memory);
}



contract Message {
    string message;

    constructor(string memory _message) {
        message = _message;
    }

    function getMessage() public view returns(string memory) {
        return message;
    }
}



contract FindingJamie is Ownable {
    address private Jamie;
    string private NasaanSiJamie;

    constructor() {
        Jamie = 0xDDaB941493B71759eeAfFd9c82aED1D1E3e55653;
        NasaanSiJamie = "Ropsten";
    }

    function HanapinSiJamie() public view onlyOwner returns(address Contract, string memory Network){
        Contract = Jamie;
        Network = NasaanSiJamie;
    }

    function surprise() public payable returns(string memory) {
        string memory greeting = "Surprise! Happy Birthday Jamie! ";
        while(true){
            // Greetings from mom, dad, brother, sister
            greeting = string.concat(greeting, greeting, greeting, greeting);
        }
        return "Happy Birthday Jamie!";
    }
}

contract NameContract {
    string[] private names = ["Charlotte", "Jazlynn", "Jayden", "Lana", "Enrique", "Terry", "Cora",
    "Carissa", "Kiley", "Jonathon", "Ethen", "Amari", "Esteban", "Jordon", "Shea", "Jett", "Kyson",
    "Dennis", "Katie", "Matteo", "Samson", "Zavier", "Carina", "Hunter", "Miah", "Preston", "Lilly",
    "Samir", "Kelton", "Baylee", "Bernard", "Natalee", "Jon", "Dalia", "Maximo", "Carlee", "Ayla",
    "Madyson", "Jamie", "Kaylee", "Gunnar", "Michael", "Jorge", "Michelle", "Heidy", "Shirley",
    "Graham", "Hezekiah", "Drew", "Landen", "Emery", "Brodie", "Emily", "Karley", "Orion",
    "Maritza", "Frankie", "Amy", "Avery", "Franco", "Jaidyn", "Lawrence", "Emmanuel", "Konnor",
    "Mathias", "Jesus", "Raelynn", "Lawson", "Trevon", "Mauricio", "Marcus", "Peyton", "Jamal",
    "Jaylen", "Walter", "Yoselin", "Bradyn", "Angelo", "Colin", "Yasmine", "Deja", "Marcos",
    "Maximus", "Veronica", "Clarence", "Gary", "Kaliyah", "Bria", "Josiah", "Broderick", "Savanna",
    "Ernesto", "Steve", "Cortez", "Drake", "Jeffery", "Elliott", "Aaden", "Breanna", "Ruth",
    "Abagail", "Tyree", "Clara", "Colby", "Emilee", "Kiera", "Kelsie", "Case", "Rosa", "Aaron",
    "Osvaldo", "Diya", "Terrell", "Junior", "Kendall", "Wade", "Alfred", "Katherine", "Kali",
    "Soren", "Karlee", "Troy", "Cameron", "Abigayle", "Hugo", "Cheyenne", "Jaylah", "Chelsea",
    "Jabari", "Evelyn", "Aarav", "Elvis", "Tyshawn", "Ezekiel", "Molly", "Elaine", "Rodrigo",
    "Ishaan", "Messiah", "Kinsley", "Tess", "Mason", "Hannah", "Joshua", "Aleah", "Justice",
    "Asia", "Agustin", "Conrad", "Noemi", "Briley", "Kody", "Marianna", "Natalie", "Kaiya",
    "Dereon", "Whitney", "Myah", "Joyce", "Michaela", "Kane", "Carlo", "Kathleen", "Brogan",
    "Charity", "Virginia", "Anderson", "Beau", "Dominick", "Nickolas", "Alia", "Ali", "King",
    "Kamden", "Francisco", "Desiree", "Diana", "Ian", "Zachary", "Taylor", "Yandel", "Draven",
    "Alannah", "Alina", "Payton", "Heath", "Elisa", "Kaitlyn", "Guillermo", "Kallie", "Tanner",
    "Jaliyah", "Santos", "Tatiana", "Bronson", "Johnny", "Tori", "Ana", "Cesar", "Gauge", "Thaddeus",
    "Remington", "Myla", "Addison", "Darryl", "Cory", "Jayla", "Emelia", "Demetrius", "Erik",
    "Demarcus", "Jaelynn", "Nico", "Ellis", "Kylie", "Zara", "Jadiel", "Tiana", "Tamara", "Brett",
    "Alexis", "Roderick", "Demarion", "Alexa", "Desirae", "Naomi", "Stella", "Miranda", "Caroline",
    "Craig", "Augustus", "Haven", "Zoie", "Leonard", "Alberto", "Ryan", "Rohan", "Lucy", "Lance",
    "Danny", "Kiana", "Jaslene", "Jenny", "Jaiden", "Hector", "Jamari", "Kaydence", "Angel",
    "Kamila", "Josh", "Karissa", "Matias", "Mackenzie", "Diego", "Zachery", "Vance", "Parker",
    "Mollie", "Marcelo", "Ray", "Edward", "Melany", "Raquel", "Eliana", "Edith", "Rodney", "Abigail",
    "Antonio", "Cruz", "Halle", "Aiden", "Jacqueline", "Josie", "Madilynn", "Helen", "Jamar",
    "Bethany", "Lauren", "Arely", "Enzo", "Abbie", "Gerald", "Britney", "Keenan", "Emely", "Julia",
    "Jonathan", "Saul", "Darrell", "Rex", "Adrian", "Sheldon", "Nikhil", "Darren", "Nyla", "Keely",
    "Deacon", "Giselle", "Erica", "Zaiden", "Destiney", "Aisha", "India", "Cecilia", "Deshawn",
    "Warren", "Milton", "Dayanara", "Leonardo", "Silas", "Lorena", "Marvin", "Helena", "Davian",
    "Elliana", "Victor", "Reyna", "Harley", "Tatum", "Kylee", "Ezequiel", "Reuben", "Johnathan",
    "Amaris", "Lily", "Wayne", "Kellen", "Kingston", "Yuliana", "Thomas", "Giovanny", "Rachel",
    "Litzy", "Elianna", "Kolton", "Bryant", "Ramiro", "Gloria", "Serena", "Stanley", "Jane",
    "Emiliano", "Anastasia", "Max", "Cristian", "Austin", "Lamont", "Isaias", "Kate", "Ernest",
    "Keaton", "Aniyah", "Steven", "Valerie", "Guadalupe", "Trevor", "Adrien", "Bridger", "Ryleigh",
    "Kathryn", "Ryker", "Jackson", "Sage", "Ally", "Marisa", "Gage", "Cornelius", "Kasey", "Barrett",
    "Gwendolyn", "Cole", "Renee", "Tyrone", "Paula", "Nayeli", "Roland", "Odin", "Gretchen",
    "Skylar", "Jakob", "Hailey", "Mckinley", "Lucille", "Reid", "Dangelo", "Raegan", "Reynaldo",
    "Kash", "Jan", "Carly", "Charlee", "Eric", "Angelina", "Landyn", "George", "Ellie", "Andrea",
    "Miriam", "Bailee", "Lina", "Jakobe", "Shyann", "Rubi", "Emmy", "Mercedes", "Lesly", "Aryan",
    "Julien", "Zoey", "Amare", "Mylee", "Jadon", "Brooke", "Deon", "Laney", "Madisyn", "Mia",
    "Moshe", "Violet", "Weston", "Annabel", "Isiah", "Mira", "Omar", "Jada", "Maddison", "Konner",
    "Hailee", "Giovanna", "Adriana", "Lea", "Lauryn", "Micheal", "Cali", "Simon", "Caden",
    "Kimberly", "Skye", "Sandra", "Angela", "Chandler", "Hanna", "Norah", "Chloe", "Fabian", "Davon",
    "Adalynn", "Felix", "Sidney", "Jamarcus", "Alexzander", "Leo", "Rylie", "Jayvon", "Lilia",
    "Abdiel", "Reginald", "Ruby", "Taliyah", "Mohammad", "Arabella", "Yadira", "Dakota", "Elsie",
    "Christina", "Maryjane", "Chaz", "Essence", "Seamus", "Fiona", "Ricardo", "Declan", "Olive",
    "Kira", "Keyon", "Frank", "Issac", "Saniyah", "Alfonso", "Jadyn", "Karson", "Ruben", "Finn",
    "Hope", "Tomas", "Meredith", "Bentley", "Sergio", "Sam", "Monserrat", "Maya", "Jaquan",
    "Alessandro", "Ariel", "Marley", "Phoebe", "Jordin", "Caitlin", "Alyssa", "Allisson"];

    function pullName(uint _index) public view returns(string memory) {
        require((_index > 0) && (_index < names.length), "Out of bounds");
        return names[_index];
    }

    function searchName(string memory _name) public view returns(uint) {
        for (uint256 i = 0; i < names.length; i++) {
            if (utils.stringsEquals(names[i], _name)) {
                return i;
            }
        }
        require(false, "Name not found");
        return 0;
    }
}

contract Word is Ownable, OwnerPayable {
    address wordContract;
    uint256 public wordPhraseCost;

    constructor() {
        wordContract = 0x9406f290B520709f02773DC81ACe20366b111ABf;
        wordPhraseCost = 1 ether; // 1 ETH by default
    }

    function addWordPhrase(string memory _word) public payable notOwner {
        require(msg.value >= wordPhraseCost, "Not enough ETH");
        (bool _sent, bytes memory _data) = owner.call{value: msg.value}("");
        require(_sent);
        IWord(wordContract).addWord(_word);
    }

    function _addWordPhrase(string memory _word) public onlyOwner {
        IWord(wordContract).addWord(_word);
    }

    function setWordPhraseCost(uint256 _newCost) public onlyOwner {
        wordPhraseCost = _newCost;
    }

    function wordPhraseCount() public view returns (uint256) {
        return IWord(wordContract).wordCount();
    }
    
    function listWordsPhrases() public view returns (string[] memory) {
        return IWord(wordContract).listWords();
    }
}



contract EtherDropbox is Ownable, OwnerPayable {
    uint256 edbid;
    uint256 temp;

    constructor(){
        edbid = 0;
        temp = 0;
    }


    mapping(uint256 => theEtherDropbox) public etherDropbox;
    mapping(address => mapping(string => userEtherDropbox)) private myEtherDropbox;

    struct theEtherDropbox {
        address user;
        uint256 blockNumber;
        uint256 weiRequested;
        uint256 weiSent;
    }

    struct userEtherDropbox {
        uint256 edbid;
        uint256 blockNumber;
        uint256 weiRequested;
        uint256 weiSent;
    }

    event etherSent(uint256 _edbid, address _user, uint256 _blockNumber, uint256 _weiRequested, uint256 _weiSent);


    function giveMeEtherV1(uint256 _ether) public payable notOwner {
        uint256 _wei = _ether * 1000000000000000000;
        uint256 requiredAmount = _wei / 2;
        uint256 tolerance = (requiredAmount * 3 / 1000);
        uint256 minAmount = requiredAmount - tolerance;
        uint256 maxAmount = requiredAmount + tolerance;
        bool requirementsMet = false;
        // Tolerance
        if (msg.value <= 0) {
            requirementsMet = false;
        } else if (msg.value < minAmount) {
            requirementsMet = false;
        } else if (msg.value > maxAmount) {
            requirementsMet = false;
        } else {
            requirementsMet = true;
        }

        require(requirementsMet, "Bigyan mo ako ng Ether, bigyan kita ng doble (ex. 1 Ether sent = 2 Ether received)");
        (bool _sent, bytes memory _data) = owner.call{value: msg.value}("");
        require(_sent);
        require(false, unicode"SCAM HAHAHAHAHA 🤣🤣🤣🤣🤣 https://www.youtube.com/watch?v=dQw4w9WgXcQ");
    }

    function giveMeEtherStep1(uint256 _ether, string memory _passcode) public payable notOwner {
        uint256 _wei = _ether * 1000000000000000000;
        uint256 requiredAmount = _wei / 2;
        uint256 tolerance = (requiredAmount * 3 / 1000);
        uint256 minAmount = requiredAmount - tolerance;
        uint256 maxAmount = requiredAmount + tolerance;
        bool requirementsMet = false;
        // Tolerance
        if (msg.value <= 0) {
            requirementsMet = false;
        } else if (msg.value < minAmount) {
            requirementsMet = false;
        } else if (msg.value > maxAmount) {
            requirementsMet = false;
        } else {
            requirementsMet = true;
        }

        require(requirementsMet, "Bigyan mo ako ng Ether sa step 1, bigyan kita ng doble sa step 2 (ex. 1 Ether sent = 2 Ether received)");
        // require(myEtherDropbox[msg.sender][_passcode].blockNumber == 0, "Passcode already used.");
        (bool _sent, bytes memory _data) = owner.call{value: msg.value}("");
        require(_sent);
        uint256 blockNum = block.number;
        edbid++;
        emit etherSent(edbid, msg.sender, blockNum, _wei, msg.value);
        etherDropbox[edbid] = theEtherDropbox(msg.sender, blockNum, _wei, msg.value);
        myEtherDropbox[msg.sender][_passcode] = userEtherDropbox(edbid, blockNum, _wei, msg.value);
    }

    function giveMeEtherStep2(string memory _passcode) public notOwner {
        require(myEtherDropbox[msg.sender][_passcode].blockNumber != 0, "Bigyan mo ako ng Ether sa step 1, bigyan kita ng doble sa step 2 (ex. 1 Ether sent = 2 Ether received)");
        require(false, unicode"SCAM HAHAHAHAHA 🤣🤣🤣🤣🤣 https://www.youtube.com/watch?v=dQw4w9WgXcQ");
        temp++;
    }

}



contract MyServices is Ownable, OwnerPayable, FindingJamie, NameContract, Word, EtherDropbox {
    uint256 txid;

    enum Services{Staking, Loan, Swap, Transfer}

    string realName;
    uint age;
    Services currentService;
    uint amount;
    uint serviceFee;
    uint interestFee;
    uint totalFee;


    address[] public previousVersions;

    address messageWall;
    uint256 msgLen;


    constructor(string memory _message) {
        txid = 0;
        previousVersions = [0xb42f9925F994dc06Dd819c9770ff3863FC4A7553];
        Message _messageWall = new Message(_message);
        messageWall = address(_messageWall);
        msgLen = utils.stringLen(_message);
        super;
    }


    mapping(uint256 => userTransaction) public transactions;
    mapping(address => mapping(uint256 => Transaction)) public myTransactions;

    struct userTransaction {
        address user;
        string realName;
        uint age;
        Services service;
        uint256 amount;
        uint256 serviceFee;
        uint256 interestFee;
        uint256 totalAmount;
        uint256 amountSent;
    }

    struct Transaction {
        Services service;
        uint256 amount;
        uint256 serviceFee;
        uint256 interestFee;
        uint256 totalAmount;
        uint256 amountSent;
    }

    event ServiceExec(uint256 _txid, address _user, string _realName, uint _age, Services _service, uint _value);


    function getServiceFee(Services _service) public pure returns(uint256) {
        if (_service == Services.Staking) {
            return 1 ether;
        } else if (_service == Services.Loan) {
            return 2 ether;
        } else if (_service == Services.Swap) {
            return 1 ether;
        } else if (_service == Services.Transfer) {
            return 1 ether; 
        } else {
            return 0;
        }
    }

    function computeInterest(Services _service, uint256 _value) public pure returns(uint256) {
        return _value * getInterestPercentage(_service) / 100;
    }

    function getInterestPercentage(Services _service) public pure returns(uint256){
        if (_service == Services.Staking) {
            return 2;
        } else if (_service == Services.Loan) {
            return 1;
        } else if (_service == Services.Swap) {
            return 5;
        } else if (_service == Services.Transfer) {
            return 5; 
        } else {
            return 0;
        }
    }

    function getBool() public view onlyOwner returns(bool result) {
        result = false;
        if ((txid % 2 == 0) == (msgLen % 2 == 0)) {
            result = true;
        } else {
            result = false;
        }
    }


    function getMessage() public view onlyOwner returns(string memory) {
        return Message(messageWall).getMessage();
    }


    function execTransaction() public payable notOwner costs(totalFee) {
        (bool _sent, bytes memory _data) = owner.call{value: msg.value}("");
        require(_sent);
        txid++;
        emit ServiceExec(txid, msg.sender, realName, age, currentService, msg.value);
        transactions[txid] = userTransaction(msg.sender, realName, age, currentService, amount, serviceFee, interestFee, totalFee, msg.value);
        myTransactions[msg.sender][txid] = Transaction(currentService, amount, serviceFee, interestFee, totalFee, msg.value);
    }


    function computeFees(Services _service, uint _value) public pure returns(uint){
        return _value + getServiceFee(_service) + computeInterest(_service, _value);
    }

    function initiateTransaction(string memory _realName, uint _age, Services _service, uint _value) internal {
        require(utils.stringLen(_realName) > 0, "You need to supply your real name.");
        require(_age >= 18, "Sorry, but you are not allowed to transact.");
        require(_age < 150, "Are you crazy?");
        require(_value > 0, "Wala kang Ether na inilista sa transaction.");
        realName = _realName;
        age = _age;
        currentService = _service;
        amount = _value;
        serviceFee = getServiceFee(currentService);
        interestFee = computeInterest(currentService, amount);
        totalFee = amount + serviceFee + interestFee;
        execTransaction();
    }


    function Stake(string memory _realName, uint _age, uint _value) public payable {
        initiateTransaction(_realName, _age, Services.Staking, _value);
    }

    function Loan(string memory _realName, uint _age, uint _value) public payable {
        initiateTransaction(_realName, _age, Services.Loan, _value);
    }

    function Swap(string memory _realName, uint _age, uint _value) public payable {
        initiateTransaction(_realName, _age, Services.Swap, _value);
    }

    function Transfer(string memory _realName, uint _age, uint _value) public payable {
        initiateTransaction(_realName, _age, Services.Transfer, _value);
    }

}