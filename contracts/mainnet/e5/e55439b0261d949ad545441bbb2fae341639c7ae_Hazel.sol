// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

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

contract Hazel is IERC1155 {

    address admin;
    bool initialized;
   
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
  function name() external pure returns (string memory) {
    return "Hazel";
  }

  function symbol() external pure returns (string memory) {
    return "WOOFS";
  }

function mint(uint256 quantity) external {
     _mint(msg.sender, 1, quantity);
  }

   function _mint(address _to, uint256 _id, uint256 _amount) internal {
        balances[_to][_id] += _amount; 
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);
   }
    
   function _burn(address _from, uint256 _id, uint256 _amount) internal {
        balances[_from][_id] -= _amount;
        emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
   }

function initialize() public {
    require(!initialized, "Already initialized");
    admin = msg.sender;
    initialized = true;
}

    /***********************************|
    |     On Chain Video              |
    |__________________________________*/


    function getTokenURI(uint256 id_) public view returns (string memory) {
        
        string memory videoURI = "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";
        
        string memory docURI =  string.concat('<html><body><video autoplay controls src="data:video/mp4;base64,', videoURI, '" >',
                                    '</video></body></html>');
        bytes memory imageSvg = abi.encodePacked('"animation_url": "data:text/html;base64,', Base64.encode(bytes(docURI)),'",');
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Hazel","description":"0xHuskys dog. 100% onchain video",',
                                imageSvg,
                                '"attributes": []}'                                
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