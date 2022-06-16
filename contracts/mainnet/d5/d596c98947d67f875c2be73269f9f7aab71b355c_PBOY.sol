// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

///                                      .     ... . ..::-==--::::.      ..                  
///                                    .-:---:-=-==-----::------=-===-==-======:.             
///                                    ----:--------:::::::::::------------------*.           
///                                   :=--:------==-::::::::-::------------==---++            
///                                   -==---==------:::::-::::::----------=+=--=*:            
///                                   ----:-=------:::::::::::::::--------===-=+*.            
///                                 :---:-----::::::::::::::::--::-----------===+             
///                                :=------:::::::::::::::::::--::---------=====+-            
///                             :::-------::::::::::::----::----:=++==----========.           
///                             .--::---::-::-::--:-=*#%*=--:--:=%%@%*-------====+-           
///                             .-::::::-::-------==#@@@%=-----:-#@@%+:-:-----=---+:          
///                             :--:::::----:::::-:-=+**=::--+++-:=#+-----:--------*.         
///                           .:---:::::---::::::::::::::--=%@@@@+=+**+=-:---:--:--+-         
///                          :--::::::::------:::-::-::::-=+#@@@%+*****+=--:------=+.         
///                         .--::::::::::-------:::=++##=++#%@@%##*##**+=-:--:----+=.         
///                        .==-:-:-::::::------------::-*%%+*##*%@#*+++==--::----=+*=         
///                         ---:::----:------------=--:::-*#**#**##*=:::---::----=++*         
///                        .---:::::::-----=--------==-::-:-+*****+=--------------=+*         
///                        ==--:::::::---------------=====-:--==------------------++*=        
///                        =---::::::-:-::------------=======------=====------=---==+*+.      
///                      :----:::::::::--:-:--:---------------==-----------========++++       
///                     :+=---::::-::::::-====-==--=--------:--:-----============+++*%-       
///                    .=+-------:-::------=======----=--------------=+++=++++=++++++#:       
///                    :++=--------------===++=----=----:--:--------===++++++=+++******:      
///                    :*==---------------=====--------------:-::------====+++++++=++==*.     
///                   =*===----------------=-====----------------------==--=+*++===----+:     
///                  :+===-----------::---=-----=--=-----------==---=========+*+========*-    
///                 -*====---------::-----====-=---=+==--------==============+**+======**:    
///               -#+===--------------:----=======-====---------=====+=--====+#**++++==+*     
///               ++----------------::--:---==========--=--------===++=--=++=+%#*++****%-     
///             -*=--------------------------=+=======------------=+*+----=+++%#*++++*#+      
///           :++--------------:----:--------=+++=======---------=++**+=---=++%##*+++*%-      
///         =#==---------------:-------------==++========--===+++#%%##*+=--==+%%#**+===*.     
///       :=*=-----------------:------------======+==========++*#+:..-+*+-==+%%##*+----+*:    
///      #*=-------------------------------=======-=*++===+++++***:    .---- *##**=-----=+:   
///     -#+----:------------------------=======-----+++++++**+++- .          :%**=-----==++   
///    :#=--:--:--::-------------------=========-=--==+++***:.:               #+=------===+.  
///   .*+---:-::::--------------------=============+++*****%=                 **==----==-=*=  
///  :**-----::::---:------:--:-:-:----=--=+========++**#**##*:               +#++=----==-+*: 
/// :#+---:----:--------:-----:-----------==++++=-==+****+==+*##+.            .#%**==---===++ 
/// *#*=---::----:------------:--:-----------=++++=+=++**#*+++***%+             =##=--=====+%.
///  :#=----------------------:--:----------===++++++=-=+*+*++++***+.             ==+--====+*-
///   :*++=--:--------------:::--------------===++==++--=++++++*#****%-             .==-=+***-
///     :*===-------------------------==-==---=====++=---=+##****##*#+==              :===**+ 
///     :#**=-------==----------------===+=========++------=+*##%##*.                   .     
///      %#+++=-==--=------------------==+========++==------:--==*.                           
///      -:*#*+=+=-+=-------------=--=--=**+++*===----==--===%*=--==:                         
///        :-#%*#*===+-------===-======--==. .:*---::=-===-*#*+#%#==+                         
///          :+*-==+#**-==--===++-+..:=..=-     :---------=##*+**++=.                         
///                :=: -=:.:-=    =.             :---------++#*=+*-                           
///                          --   .                --------=*+::.                             
///                                                 :------+:                                 

import "./Ownable.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/// @author jolan.eth
contract PBOY is Ownable {
    string public symbol = "PBOY";
    string public name = "Lady with Pomeranian";

    string public CID;
    
    address public ADDRESS_SIGN = 0x1Af70e564847bE46e4bA286c0b0066Da8372F902;
    address public ADDRESS_GENESIS = 0x038ddE6a3d83b3aAf9E16735F630713a650cBd86;

    address public ADDRESS_PBOY = 0x709e17B3Ec505F80eAb064d0F2A71c743cE225B3;
    address public ADDRESS_JOLAN = 0x51BdFa2Cbb25591AF58b202aCdcdB33325a325c2;

    uint256 public SHARE_PBOY = 90;
    uint256 public SHARE_JOLAN = 10;

    uint256 public price = 1 ether;

    uint256 public step = 0;

    uint256 public maxStep = 7;
    uint256 public maxPerStep = 7;
    uint256 public stepCounter = 7;
    
    uint256 public tokenId = 1;
    uint256 public totalSupply = 50;

    mapping (uint256 => address) owners;
    mapping(address => uint256) balances;
    
    mapping(uint256 => address) approvals;
    mapping(address => mapping(address => bool)) operatorApprovals;

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {
        _mint(ADDRESS_GENESIS, tokenId++);
    }

    receive() external payable {}

    function mintPBOY() public payable {
        require(step > 0 && step <= maxStep);
        require(stepCounter < maxPerStep);
        require(msg.value == price);
        require(tokenId <= totalSupply);

        _mint(msg.sender, tokenId++);
        stepCounter++;
    }

    function setCID(string memory _CID) public onlyOwner {
        CID = _CID;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setStep() public onlyOwner {
        require(tokenId < totalSupply);
        if (stepCounter < maxPerStep) {
            while (stepCounter < maxPerStep) {
                _mint(msg.sender, tokenId++);
                stepCounter++;
            }
        }

        if (step < maxStep) {
            stepCounter = 0;
            step++;
            _mint(msg.sender, tokenId++);
            stepCounter++;
        }
    }

    function setPboy(address _PBOY)
    public {
        require(msg.sender == ADDRESS_PBOY, "error msg.sender");
        ADDRESS_PBOY = _PBOY;
    }

    function setJolan(address _JOLAN)
    public {
        require(msg.sender == ADDRESS_JOLAN, "error msg.sender");
        ADDRESS_JOLAN = _JOLAN;
    }

    function withdrawEquity()
    public onlyOwner {
        uint256 balance = address(this).balance;

        address[2] memory shareholders = [
            ADDRESS_PBOY,
            ADDRESS_JOLAN
        ];

        uint256[2] memory _shares = [
            SHARE_PBOY * balance / 100,
            SHARE_JOLAN * balance / 100
        ];

        uint i = 0;
        while (i < 2) {
            require(payable(shareholders[i]).send(_shares[i]));
            i++;
        }
    }

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function balanceOf(address owner)
    public view returns (uint256) {
        require(address(0) != owner, "error address(0)");
        return balances[owner];
    }

    function ownerOf(uint256 id)
    public view returns (address) {
        require(owners[id] != address(0), "error !exist");
        return owners[id];
    }

    function tokenURI(uint256 id)
    public view returns (string memory) {
        require(owners[id] != address(0), "error !exist");
        return string(abi.encodePacked("ipfs://", CID, "/", _toString(id)));
    }

    function approve(address to, uint256 id)
    public {
        address owner = owners[id];
        require(to != owner, "error to");
        require(
            owner == msg.sender ||
            operatorApprovals[owner][msg.sender],
            "error owner"
        );
        approvals[id] = to;
        emit Approval(owner, to, id);
    }

    function getApproved(uint256 id)
    public view returns (address) {
        require(owners[id] != address(0), "error !exist");
        return approvals[id];
    }

    function setApprovalForAll(address operator, bool approved)
    public {
        require(operator != msg.sender, "error operator");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
    public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 id)
    public {
        require(owners[id] != address(0), "error !exist");
        address owner = owners[id];
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender], 
            "error msg.sender"
        );

        _transfer(owner, from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes memory data)
    public {
        address owner = owners[id];
        require(
            msg.sender == owner ||
            msg.sender == approvals[id] ||
            operatorApprovals[owner][msg.sender], 
            "error msg.sender"
        );
        _transfer(owner, from, to, id);
        require(_checkOnERC721Received(from, to, id, data), "error ERC721Receiver");
    }

    function _mint(address to, uint256 id)
    private {
        require(to != address(0), "error to");
        require(owners[id] == address(0), "error owners[id]");
        emit Transfer(address(0), ADDRESS_SIGN, id);

        balances[to]++;
        owners[id] = to;
        
        emit Transfer(ADDRESS_SIGN, to, id);
        require(_checkOnERC721Received(ADDRESS_SIGN, to, id, ""), "error ERC721Receiver");
    }

    function _transfer(address owner, address from, address to, uint256 id)
    private {
        require(owner == from, "errors owners[id]");
        require(address(0) != to, "errors address(0)");

        approve(address(0), id);
        balances[from]--;
        balances[to]++;
        owners[id] = to;
        
        emit Transfer(from, to, id);
    }

    function _checkOnERC721Received(address from, address to, uint256 id, bytes memory _data)
    internal returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(to)
        }

        if (size > 0)
            try ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, _data) returns (bytes4 retval) {
                return retval == ERC721TokenReceiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) revert("error ERC721Receiver");
                else assembly {
                        revert(add(32, reason), mload(reason))
                    }
            }
        else return true;
    }
    
    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) return "0";

        uint256 digits;
        uint256 tmp = value;

        while (tmp != 0) {
            digits++;
            tmp /= 10;
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