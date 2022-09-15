// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./bogo.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
contract I_AM_THE_REDARD is BogoSort{
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory) {
        return "ipfs://bafybeigoi3rncqkwxa4i6zkfwjkkul6zzs4tgnl5knap4arwna2upqgsne";
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                    BOGO SORT COMMITMENT STORAGE
    //////////////////////////////////////////////////////////////*/

    struct commitment {
        uint256 value;
        uint256 blockNumber;
    }
    mapping (address => commitment) commitments;
    

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        name = "I_AM_THE_REDARD";
        symbol = "BOGO";
        _mint(msg.sender, 0);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferBOnGOCAT(address to) private {
        emit Transfer(_ownerOf[0], to, 0);
        
        unchecked {
            _balanceOf[_ownerOf[0]]--;
            _ownerOf[0] = to;
            _balanceOf[_ownerOf[0]]++;
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    /*//////////////////////////////////////////////////////////////
                                BOGO SORT
    //////////////////////////////////////////////////////////////*/

    event Commited(address victim, uint256 blockNumber);    

    function commit (uint256 _commitment) public {
        commitments[msg.sender] = commitment(_commitment, block.number);
        emit Commited(msg.sender, block.number);
    }

    function BECOME_THE_RETARD () public {
        require (commitments[msg.sender].blockNumber < block.number || (block.number - commitments[msg.sender].blockNumber) < 100, "PLEASE_WAIT_OR_COMMIT_AGAIN");
        
        // Reset commitment
        uint256 temp = commitments[msg.sender].value;
        commitments[msg.sender].value = 0;
        commitments[msg.sender].blockNumber = 0;
        
        if (sort(temp)) {
            transferBOnGOCAT(msg.sender);
        }
    }
    

}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

pragma solidity ^0.8.0;

contract BogoSort {
    uint[] private array;
    uint256 private nonce;

    constructor() {
        array = [21, 515, 123, 12, 123, 15782, 431, 6823412, 16479126, 13812];
    }

    function sort(uint256 _commitment) internal returns (bool) {
        array = bogo(array, _commitment);
        shuffle(array, _commitment);
        return true;
    }

    function bogo(uint[] memory _array, uint256 _commitment) private returns(uint[] memory) {
        while (!isSorted(_array)) {
            _array = shuffle(_array, _commitment);
        }
        return _array;
    }

    function isSorted(uint[] memory _array) private pure returns(bool) {
        for (uint i = 0; i < _array.length - 1; i++) {
            if (!(_array[i] <= _array[i+1])) {
                return false;
            }
        }
        return true;
    }

    function shuffle(uint[] memory _array, uint256 _commitment) private returns(uint[] memory) {
        for (uint i = 0; i < _array.length; i++) {
			uint nonce = random(i, _commitment);
			uint temp = _array[nonce];
			_array[nonce] = _array[i];
			_array[i] = temp;
        }
        return _array;
    }

    function random(uint256 _nonce, uint256 _commitment) private returns (uint) {
        nonce += _nonce;
        uint temp = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce, _commitment)));
        // keccak should always return a fixed lenght number so we can just do this
        while (temp >= 9) {
            temp = temp / 10;
        }
        return temp;
    }
}