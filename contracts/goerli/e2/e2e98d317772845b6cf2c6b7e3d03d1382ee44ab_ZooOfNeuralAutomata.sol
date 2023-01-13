// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IZooOfNeuralAutomata} from "./interfaces/IZooOfNeuralAutomata.sol";
import {INeuralAutomataEngine, NCAParams} from "./interfaces/INeuralAutomataEngine.sol";
import {ERC1155} from "../lib/solmate/src/tokens/ERC1155.sol";
import {Owned} from "../lib/solmate/src/auth/Owned.sol";
import {Base64} from "./utils/Base64.sol";

contract ZooOfNeuralAutomata is IZooOfNeuralAutomata, ERC1155, Owned {

    string public name = "Zoo of Neural Automata";
    string public symbol = "ZoNA";
    string public contractURI;

    address public engine;
 
    mapping(uint256 => NCAParams) public tokenParams;
    mapping(uint256 => address) public tokenMinter;
    mapping(uint256 => address) public tokenBurner;
    mapping(uint256 => string) public tokenBaseURI;
    mapping(uint256 => bool) public tokenFrozen;

    modifier onlyUnfrozen(uint256 _id){
        require(!tokenFrozen[_id]);
        _;
    }

    constructor(
        address _engine, 
        string memory _contractURI
    ) Owned(msg.sender) {
        engine = _engine;
        contractURI = _contractURI;
    }

    function newToken(
        uint256 _id,
        NCAParams memory _params, 
        address _minter, 
        address _burner,
        string memory _baseURI
    ) external onlyOwner onlyUnfrozen(_id) {
        tokenParams[_id] = _params;
        tokenMinter[_id] = _minter;
        tokenBurner[_id] = _burner;
        tokenBaseURI[_id] = _baseURI;
    }

    function updateParams(
        uint256 _id, 
        NCAParams memory _params
    ) external onlyOwner onlyUnfrozen(_id) {
        tokenParams[_id] = _params;
    }

    function updateMinter(
        uint256 _id, 
        address _minter
    ) external onlyOwner onlyUnfrozen(_id) {
        tokenMinter[_id] = _minter;
    }

    function updateBurner(
        uint256 _id, 
        address _burner
    ) external onlyOwner onlyUnfrozen(_id) {
        tokenBurner[_id] = _burner;
    }

    function updateBaseURI(
        uint256 _id, 
        string memory _baseURI
    ) external onlyOwner onlyUnfrozen(_id) {
        tokenBaseURI[_id] = _baseURI;
    }

    function freeze(uint256 _id) external onlyOwner {
        tokenFrozen[_id] = true;
    }

    function updateEngine(address _engine) external onlyOwner  {
        engine = _engine;
    }

    function updateContractURI(string memory _contractURI) external onlyOwner  {
        contractURI = _contractURI;
    } 

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external {
        require(msg.sender == tokenMinter[_id]);
        _mint(_to, _id, _amount, "");
    }

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external {
        require(msg.sender == tokenBurner[_id]);
        _burn(_from, _id, _amount);
    }

    function uri(uint256 id) public view override returns (string memory){
        require(tokenMinter[id] != address(0));
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    string.concat(
                        tokenBaseURI[id],
                        "\"",
                        INeuralAutomataEngine(engine).page(tokenParams[id]),
                        "\"}"
                    )
                )
            )
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

struct NCAParams {
    string seed;
    string bg;
    string fg1;
    string fg2;
    string matrix;
    string activation;
    string rand;
    string mods;
}

interface INeuralAutomataEngine {
    function baseScript() external view returns(string memory);

    function parameters(NCAParams memory _params) external pure returns(string memory);

    function p5() external view returns(string memory);

    function script(NCAParams memory _params) external view returns(string memory);

    function page(NCAParams memory _params) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {NCAParams} from "./INeuralAutomataEngine.sol";

interface IZooOfNeuralAutomata {

    function updateEngine(address _engine) external;

    function updateContractURI(string memory _contractURI) external;

    function updateParams(uint256 _id, NCAParams memory _params) external;

    function updateMinter(uint256 _id, address _minter) external;

    function updateBurner(uint256 _id, address _burner) external;

    function updateBaseURI(uint256 _id, string memory _baseURI) external;

    function freeze(uint256 _id) external;

    function newToken(
        uint256 _id,
        NCAParams memory _params, 
        address _minter, 
        address _burner,
        string memory _baseURI
    ) external;

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) public pure returns (string memory) {
      if (data.length == 0) return "";

      string memory table = _TABLE;
      string memory result = new string(4 * ((data.length + 2) / 3));

      assembly {
          let tablePtr := add(table, 1)
          let resultPtr := add(result, 32)

          for {
              let dataPtr := data
              let endPtr := add(data, mload(data))
          } lt(dataPtr, endPtr) {

          } {
              dataPtr := add(dataPtr, 3)
              let input := mload(dataPtr)
              mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
              resultPtr := add(resultPtr, 1) 
              mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
              resultPtr := add(resultPtr, 1) 
              mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
              resultPtr := add(resultPtr, 1) 
              mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
              resultPtr := add(resultPtr, 1) 
          }
          switch mod(mload(data), 3)
          case 1 {
              mstore8(sub(resultPtr, 1), 0x3d)
              mstore8(sub(resultPtr, 2), 0x3d)
          }
          case 2 {
              mstore8(sub(resultPtr, 1), 0x3d)
          }
      }
      return result;
  }
}