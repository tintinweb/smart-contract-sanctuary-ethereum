/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: ERC721
pragma solidity ^0.4.26;
/**
 *
 *                                                
 *                                                ██╗░░░░░░█████╗░████████╗███████╗██████╗░██╗░█████╗░
 *                                                ██║░░░░░██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║██╔══██╗
 *                                                ██║░░░░░██║░░██║░░░██║░░░█████╗░░██████╔╝██║███████║
 *                                                ██║░░░░░██║░░██║░░░██║░░░██╔══╝░░██╔══██╗██║██╔══██║
 *                                                ███████╗╚█████╔╝░░░██║░░░███████╗██║░░██║██║██║░░██║
 *                                                ╚══════╝░╚════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░╚═╝
 *                    
 *                                                                  Dev: Bitsapiens_
 *                                                                  Dev: JdMelo182
 * 
 ******************************************************************************************************************************************
 *                       A Lottery by leves and each level has a winner.                                                                  *    
 *                                                                                                                                        *    
 *                      LEVEL_1  = 10 X 0.1 bnb       = 0.5 bnb to the winner.      || 0.5 bnb for Lottery development.                   *     
 *                      LEVEL_2  = 20 X 0.1 bnb       = 1 bnb to the winner.        || 1 bnb for Lottery development.                     *    
 *                      LEVEL_3  = 40 X 0.1 bnb       = 3 bnb to the winner.        || 1 bnb for Lottery development.                     *     
 *                      LEVEL_4  = 80 X 0.1 bnb       = 7 bnb to the winner.        || 1 bnb for Lottery development.                     *        
 *                      LEVEL_5  = 100 X 0.1 bnb      = 9 bnb to the winner.        || 1 bnb for Lottery development.                     *    
 *                      LEVEL_6  = 200 X 0.1 bnb      = 19 bnb to the winner.       || 1 bnb for Lottery development.                     *     
 *                      LEVEL_7  = 500 X 0.1 bnb      = 40 bnb to the winner.       || 10 bnb for Holders                                 *    
 *                      LEVEL_8  = 1000 X 0.1 bnb     = 70 bnb to the winner.       || 30 bnb for Holders.                                *
 *                      LEVEL_9  = 1500 X 0.1 bnb     = 105 bnb to the winner.      || 45 bnb for Holders.                                *    
 *                      LEVEL_10 = 2000 X 0.1 bnb     = 140 bnb to the winner.      || 60 bnb for Holders.                                *
 *                      LEVEL_11 = 5000 X 0.1 bnb     = 350 bnb to the winner.      || 150 bnb for Holders.                               *    
 *                      LEVEL_12 = 10000 X 0.1 bnb    = 700 bnb to the winner.      || 300 bnb for Holders.                               *
 *                      LEVEL_13 = 50000 X 0.1 bnb    = 3500 bnb to the winner.     || 1500 bnb for Holders.                              *            
 *                      LEVEL_14 = 100000 X 0.1 bnb   = 7000 bnb to the winner.     || 3000 bnb for Holders.                              *    
 ******************************************************************************************************************************************
 *          When the lottery reaches level 14, it  stay in this position with a winner of 7000 bnb each 100,000 NFTs.                   *    
 *                                                                                                                                        *
                                                            ████████████████████████████████
                                                            █▄─▄▄▀█▄─██─▄█▄─▄███▄─▄▄─█─▄▄▄▄█
                                                            ██─▄─▄██─██─███─██▀██─▄█▀█▄▄▄▄─█
                                                            ▀▄▄▀▄▄▀▀▄▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
                                                        
                            1-- Each user will have an NFT-lotto that represents the lottery ticket.
                            2-- The NFTs are interchangeable before and after the lottery.
                            3-- The lottery runs when all tickets of the level are sold.
                            4-- The winner is the owner of the winning NFTlotto.
                            5-- Holders are the owners of the NFT-lotto from level 1 to 13.
                            6-- Holders will receive 30% of the POT each time there is a winner at level 14.
                            7-- The 30% commission of the holders will be divided into equal percentages per level.
                        Mo more rules, No Roadmap, No White Papers,  No New Coins,  Only lucky, Winners and Holders.
**/
interface ERC721TokenReceiver
{

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);

}

contract NFTlotto {
    
    address private constant POT = 0x4E68a129E6AFb17BC8dD5ebD28395C0F2E4782e5;
    // DAO is the address for the creation of the web3 and the creation of the DAO for the sellers.
    uint256 public numTokens = 0; // Numero de token inicial
    uint public numTicket = 0; // numero de numTicket
    uint public numLevel = 1;  // numero de niveles
    mapping(bytes4 => bool) internal supportedInterfaces; // support
    mapping (uint256 => address) internal idToOwner;
    mapping(uint256 => uint256) internal idToOwnerIndex;
    mapping(uint256 => uint256) internal numberwin;
    mapping(address => uint256[]) internal ownerToIds;
    mapping (uint256 => string) private _tokenURIs;
    mapping(uint256 => address) private _wins;
    uint public constant Price_ticket = 0 finney;
    string internal nftName = "NFT-lotto"; // Name 
    address [] private randoms;
    string internal nftSymbol = "░"; // Simbol 
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping (uint256 => address) internal idToApproval;
    mapping (address => mapping (address => bool)) internal ownerToOperators;
    
    constructor() public {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
    }  
    
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
    
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    function getApproved(uint256 _tokenId) external view validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

        function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0));
        _;
    }
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
        _;
    }
    function setApprovalForAll(address _operator, bool _approved) external {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }

    ///////////////////////Transfer///////////////////////////////////////////////
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId)  {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));
        _transfer(_to, _tokenId);
    }
    
    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }
    

   
      ///////////////////Transfer///////////////////////////////////////////////  
    
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }
    
    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from);
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].length--;
    }
    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0));
        idToOwner[_tokenId] = _to;
        uint256 length = ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = length - 1;
    }
    function _addwin(address _to, uint256 lvl, uint256 number) internal{
        require (_wins[lvl] == address(0));
        numberwin[lvl] = number;
        _wins[lvl] = _to;
    }
    function winXlevels(uint Level) public view returns (address level) {
        require(Level > 0 && Level < 15, "There is no level 0 or levels higher than 14");
        level = _wins[Level];
        require(level != address(0));
    }
    
    function TicketWinLevel(uint Level) public view returns (uint num) {
        require(Level > 0 && Level < 15, "There is no level 0 or levels higher than 14");
        num = numberwin[Level];
        require(num != 0);
    }
    
    function tokenURI(uint id) public view returns (string){
         require(numTokens >= id, "ERC721Metadata: URI query for nbnbxistent token");
         return _tokenURIs[id];
    }
    function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }
    
    function ownerOf(uint _tokenId) public view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0));
    }
    
    function balanceOf(address _owner) external view returns (uint) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }
    function _getOwnerNFTCount(address _owner) internal view returns (uint) {
        return ownerToIds[_owner].length;
    }
    
        modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender]
        );
        _;
    }
    
  function random() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randoms)));
    }
    

    function transferTicket(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId)  {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));
        _transfer(_to, _tokenId);
    }
    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }
        function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

    function _mint(address _to) internal {
        require(_to != address(0));
        numTokens = numTokens  + 1 ;  // Aumenta el numero de numTokens
        emit Transfer(address(0), _to, numTokens);
        _addNFToken(_to, numTokens);       
    }
    
    function Lottery_execute() private {
        uint ind= 0;
        address a = (0);
        numTicket = numTicket + 1;
        
        if (numTicket == 10 && numLevel == 1){  // pregunta si ya hay 9 tickets vendidos y el levl
                ind = random()%10; // number < 10
                if(ind == 0){ind = 1;} 
                a = ownerOf(ind);  // give address
                _addwin(a, numLevel, ind);

        }if(numTokens==10){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change
        
        if (numTicket == 20 && numLevel == 2){
                ind = random()%20;
                ind = ind + 10;
                if(ind == 10){ind = 11;}
                a = ownerOf(ind);
                _addwin(a, numLevel, ind);
             
        }if(numTokens==30){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change
        
        if (numTicket == 40 && numLevel == 3){
            ind = random()%40;
            ind = ind + 30;
            if(ind == 30){ind = 31;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
           
        }if(numTokens==70){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change//
        
        if (numTicket == 80 && numLevel == 4){
            ind = random()%80;
            ind = ind + 70;
            if(ind == 70){ind = 71;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
           
        }if(numTokens==150){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change//
        
        if (numTicket == 100 && numLevel == 5){
            ind = random()%100;
            ind = ind + 150;
            if(ind == 150){ind = 151;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
            
        }if(numTokens==250){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change
        if (numTicket == 200 && numLevel == 6){
            ind = random()%200;
            ind = ind + 250;
            if(ind == 250){ind = 251;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
           
        }if(numTokens==450){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change
        if (numTicket == 500 && numLevel == 7){
            ind = random()%500;
            ind = ind + 450;
            if(ind == 450){ind = 451;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
            
        }if(numTokens==950){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change
        if (numTicket == 1000 && numLevel == 8){
            ind = random()%1000;
            ind = ind + 950;
            if(ind == 950){ind = 951;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
            
        }if(numTokens==1950){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change
        if (numTicket == 1500 && numLevel == 9){
            ind = random()%1500;
            ind = ind + 1950;
            if(ind == 1950){ind = 1951;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
           
        }if(numTokens==3450){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change
        if (numTicket == 2000 && numLevel == 10){
            ind = random()%2000;
            ind = ind + 3450;
            if(ind == 3450){ind = 3451;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
    
         
        }if(numTokens==5450){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change
        if (numTicket == 5000 && numLevel == 11){
            ind = random()%5000;
            ind = ind + 5450;
            if(ind == 5450){ind = 5451;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
  
        }if(numTokens==10450){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change
        if (numTicket == 10000 && numLevel == 12){
            ind = random()%10000;
            ind = ind + 10450;
            if(ind == 10450){ind = 10451;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
          
        }if(numTokens==20450){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change
        if (numTicket == 50000 && numLevel == 13){
            ind = random()%50000;
            ind = ind + 20450;
            if(ind == 20450){ind = 20451;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
        
           
        }if(numTokens==70450){numTicket=0;numLevel = numLevel + 1;} // only reset counter ticket and level change
        if (numTicket == 100000 && numLevel >= 14){
            ind = random()%100000;
            ind = ind + numTokens;
            if(ind == numTokens){ind = numTokens+1;}
            a = ownerOf(ind);
            _addwin(a, numLevel, ind);
            numTicket=0; 
            numLevel = numLevel+1; // reset total each 100.000 forever lvl 14. 
        }
    }
    
    
    function toString(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
    
    function Buy_Ticket(address from) external payable {
        uint amount = Price_ticket;
        require(msg.value >= amount);
        if(msg.value > amount){
            msg.sender.transfer(address(this).balance);
        }
        if(amount > 0){
           POT.transfer(amount);
        }
        _tokenURIs[numTokens] = string(abi.encodePacked("https://proofofprank.com/ticket/level",toString(numLevel),"/",toString(numTicket),".php"));
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
                             _mint(from); // mint                         
        //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            Lottery_execute();  // CheckLottery 
    }
}