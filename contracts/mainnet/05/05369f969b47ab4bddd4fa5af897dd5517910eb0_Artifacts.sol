// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

//import "hardhat/console.sol";
import "./Interfaces.sol";

/*

░█████╗░██████╗░████████╗░░██╗██╗███████╗░█████╗░░█████╗░████████╗░██████╗██╗░░
██╔══██╗██╔══██╗╚══██╔══╝░██╔╝██║██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝╚██╗░
███████║██████╔╝░░░██║░░░██╔╝░██║█████╗░░███████║██║░░╚═╝░░░██║░░░╚█████╗░░╚██╗
██╔══██║██╔══██╗░░░██║░░░╚██╗░██║██╔══╝░░██╔══██║██║░░██╗░░░██║░░░░╚═══██╗░██╔╝
██║░░██║██║░░██║░░░██║░░░░╚██╗██║██║░░░░░██║░░██║╚█████╔╝░░░██║░░░██████╔╝██╔╝░
╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░░░╚═╝╚═╝╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░╚═════╝░╚═╝░░
*/

contract Artifacts is IERC1155 {

    address admin;
    address validator;
    bool initialized;
   
    mapping(bytes => uint256) public usedSignatures; 
    mapping(address => bool) public auth;
    
    /***********************************|
    |        Variables and Events       |
    |__________________________________*/

    // onReceive function signatures
    bytes4 constant internal ERC1155_RECEIVED_VALUE       = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    mapping (address => mapping(uint256 => uint256))  internal balances;    
    mapping (address => mapping(address => bool))     internal operators;

   /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

function initialize() public {
    admin = msg.sender;
    auth[msg.sender] = true;
    initialized = true;
    validator = 0xF3c1D8E58A6d79e9db28a364b196daCD3dE42069;
}

function mint(uint256 quantity, uint256 timestamp, bytes memory tokenSignature) external {
    isPlayer();
    require(usedSignatures[tokenSignature] == 0, "Signature already used");   
    require(_isSignedByValidator(encodeTokenForSignature(quantity, msg.sender, timestamp),tokenSignature), "incorrect signature");
    usedSignatures[tokenSignature] = 1;    
    //_safeMint(msg.sender, quantity);
     _mint(msg.sender, 1, quantity);
  }

  function reserve(uint256 quantity) external {
    onlyOwner();
    _mint(msg.sender, 1, quantity);
  }

  function burn(address from,uint256 id, uint256 value) external {
        require(auth[msg.sender], "FORBIDDEN TO BURN");
        _burn(from, id, value);
   }

   function _mint(address _to, uint256 _id, uint256 _amount) internal {
        balances[_to][_id] += _amount; 
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);
   }
    
   function _burn(address _from, uint256 _id, uint256 _amount) internal {
        balances[_from][_id] -= _amount;
        emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
   }



//Permissions
function encodeTokenForSignature(uint256 quantity, address owner, uint256 timestamp) public pure returns (bytes32) {
                return keccak256(
                        abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                            keccak256(abi.encodePacked(quantity, owner, timestamp))
                                )
                            );
}  

function _isSignedByValidator(bytes32 _hash, bytes memory _signature) private view returns (bool) {
                
                bytes32 r;
                bytes32 s;
                uint8 v;
                    assembly {
                            r := mload(add(_signature, 0x20))
                            s := mload(add(_signature, 0x40))
                            v := byte(0, mload(add(_signature, 0x60)))
                        }
                    
                        address signer = ecrecover(_hash, v, r, s);
                        return signer == validator;
  
}
//ADMIN

function onlyOwner() internal view {    
    require(admin == msg.sender);
}

function onlyOperator() internal view {    
    require(auth[msg.sender] == true, "not Authorized");    
}        

function isPlayer() internal {    
    uint256 size = 0;
    address acc = msg.sender;
    assembly { size := extcodesize(acc)}
    require((msg.sender == tx.origin && size == 0));
}

function setValidator(address _validator)  public {
    onlyOwner();       
    validator  = _validator;     
}

function setAuth(address[] calldata adds_, bool status) public {
       onlyOwner();
       
        for (uint256 index = 0; index < adds_.length; index++) {
            auth[adds_[index]] = status;
        }
    }
    /***********************************|
    |     On Chain Imaging              |
    |__________________________________*/


    function getTokenURI(uint256 id_) public view returns (string memory) {
        //string memory imageURI = "https://huskies.mypinata.cloud/ipfs/QmUGnyv5SLs4QngTPnwNAE6asWouEnfuLjPHmPEKCyZFk1/1.png"    
        string memory imageURI = "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";
        string memory svgBase64 = Base64.encode(
                                            bytes(
                                                abi.encodePacked(
        '<svg id="art" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" width="100%" height="100%" >',
        '<image x="0" y="0" width="350" height="350" preserveAspectRatio="xMidYMid" image-rendering="pixelated" href="data:image/png;base64,', imageURI, '" />',
        '<style>#art{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>'  
                                                )
                                            )
                                        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Artifacts","description":"EthernalElves Artifacts is a collection of rare fragements. A combination of these artifacts can be used to awaken The Elders and other elements of the Elvenverse.",',
                                '"image": "data:image/svg+xml;base64,',svgBase64,'", "attributes": []}'                                
                            )
                        )
                    )
                )
            );
    }

   

    /***********************************|
    |     Public Transfer Functions     |
    |__________________________________*/

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
        public override
    {
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
        require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");

        _safeTransferFrom(_from, _to, _id, _amount);
        _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
        public override
    {
        // Requirements
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
        require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

        _safeBatchTransferFrom(_from, _to, _ids, _amounts);
        _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
    }


    /***********************************|
    |    Internal Transfer Functions    |
    |__________________________________*/

    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
        internal
    {
        // Update balances
        balances[_from][_id] -= _amount;
        balances[_to][_id] += _amount;

        // Emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    /**
    * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
    */
    function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data) internal {
        // Check if recipient is contract
        if (_to.code.length != 0) {
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas: _gasLimit}(msg.sender, _from, _id, _amount, _data);
        require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
        }
    }

    function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts) internal {
        require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

        // Number of transfer to execute
        uint256 nTransfer = _ids.length;

        // Executing all transfers
        for (uint256 i = 0; i < nTransfer; i++) {
            
            balances[_from][_ids[i]] -= _amounts[i];
            balances[_to][_ids[i]]   += _amounts[i];
        }

        // Emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    /**
    * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
    */
    function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data) internal {
        // Pass data if recipient is contract
        if (_to.code.length != 0) {
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
        require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
        }
    }


    /***********************************|
    |         Operator Functions        |
    |__________________________________*/


    function setApprovalForAll(address _operator, bool _approved)
        external override
    {
        // Update operator status
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator)
        public override view returns (bool isOperator)
    {
        return operators[_owner][_operator];
    }


    /***********************************|
    |         Balance Functions         |
    |__________________________________*/

    function balanceOf(address _owner, uint256 _id) public override view returns (uint256) {
        return balances[_owner][_id];
    }

    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) public override view returns (uint256[] memory) {
        require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

        // Variables
        uint256[] memory batchBalances = new uint256[](_owners.length);

        // Iterate over each owner and token ID
        for (uint256 i = 0; i < _owners.length; i++) {
        batchBalances[i] = balances[_owners[i]][_ids[i]];
        }

        return batchBalances;
    }

    function uri(uint256 _id) public view returns (string memory) {
        return getTokenURI(_id);
    }

    function owner() external view returns(address own_) {
        own_ = admin;
    }


    /***********************************|
    |          ERC165 Functions         |
    |__________________________________*/

    function supportsInterface(bytes4 _interfaceID) public override pure returns (bool) {
        if (_interfaceID == type(IERC1155).interfaceId) {
            return true;
        }
        if (_interfaceID == type(IERC1155Metadata).interfaceId) {
            return true;
        }
        return _interfaceID == this.supportsInterface.selector;
    }

}


/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERNAL ELVES TEAM.
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface IERC20Lite {
    
    function transfer(address to, uint256 value) external returns (bool);
    function burn(address from, uint256 value) external;
    function mint(address to, uint256 value) external; 
    function approve(address spender, uint256 value) external returns (bool); 
    function balanceOf(address account) external returns (uint256); 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface IElfMetaDataHandler {    
function getTokenURI(uint16 id_, uint256 sentinel) external view returns (string memory);
}

interface ICampaigns {
function gameEngine(uint256 _campId, uint256 _sector, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) external 
returns(uint256 level, uint256 rewards, uint256 timestamp, uint256 inventory);
}

interface IElves {    
    function prismBridge(uint256[] calldata id, uint256[] calldata sentinel, address owner) external;    
    function exitElf(uint256[] calldata ids, address owner) external;
    function setAccountBalance(address _owner, uint256 _amount, bool _subtract, uint256 _index) external;
}

interface IERC721Lite {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface IERC1155Lite {
    function burn(address from,uint256 id, uint256 value) external;
    function balanceOf(address _owner, uint256 _id) external returns (uint256); 
}

 
//1155
interface IERC165 {
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

interface IERC1155Metadata {
  event URI(string _uri, uint256 indexed _id);
  function uri(uint256 _id) external view returns (string memory);
}

interface IERC1155TokenReceiver {
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}