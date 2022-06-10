/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/generic/model/ILazyInitCapableElement.sol


pragma solidity >=0.7.0;


interface ILazyInitCapableElement is IERC165 {

    function lazyInit(bytes calldata lazyInitData) external returns(bytes memory initResponse);
    function initializer() external view returns(address);

    event Host(address indexed from, address indexed to);

    function host() external view returns(address);
    function setHost(address newValue) external returns(address oldValue);

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) external view returns(bool);
}
// File: contracts/lib/Creator.sol


pragma solidity >=0.7.0;

library Creator {

    event Source(address indexed sender, address indexed source);
    event Created(address indexed sender, address indexed source, address indexed destination);

    function create(bytes memory sourceAddressOrBytecode) external returns(address destination, address source) {
        if(sourceAddressOrBytecode.length == 32) {
            source = abi.decode(sourceAddressOrBytecode, (address));
        } else if(sourceAddressOrBytecode.length == 20) {
            assembly {
                source := div(mload(add(sourceAddressOrBytecode, 32)), 0x1000000000000000000000000)
            }
        } else {
            assembly {
                source := create(0, add(sourceAddressOrBytecode, 32), mload(sourceAddressOrBytecode))
            }
            emit Source(msg.sender, source);
        }
        require(source != address(0), "source");
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(source)
        }
        require(codeSize > 0, "source");
        destination = address(new GeneralPurposeProxy{value : msg.value}(source));
        emit Created(msg.sender, source, destination);
    }
}

contract GeneralPurposeProxy {

    constructor(address source) payable {
        assembly {
            sstore(0xf7e3126f87228afb82c9b18537eed25aaeb8171a78814781c26ed2cfeff27e69, source)
        }
    }

    fallback() external payable {
        assembly {
            let _singleton := sload(0xf7e3126f87228afb82c9b18537eed25aaeb8171a78814781c26ed2cfeff27e69)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch success
                case 0 {revert(0, returndatasize())}
                default { return(0, returndatasize())}
        }
    }
}
// File: contracts/lib/Initializer.sol


pragma solidity >=0.8.0;



library Initializer {

    event Created(address indexed destination, bytes lazyInitResponse);

    function create(bytes memory sourceAddressOrBytecode, bytes memory lazyInitData) external returns(address destination, bytes memory lazyInitResponse, address source) {
        (destination, source) = Creator.create(sourceAddressOrBytecode);
        lazyInitResponse = ILazyInitCapableElement(destination).lazyInit(lazyInitData);
        require(ILazyInitCapableElement(destination).initializer() == address(this));
        emit Created(destination, lazyInitResponse);
    }
}