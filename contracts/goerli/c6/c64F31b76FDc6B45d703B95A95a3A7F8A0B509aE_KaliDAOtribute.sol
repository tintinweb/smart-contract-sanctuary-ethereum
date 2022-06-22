// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

/// @notice Safe ETH and ERC-20 transfer library that gracefully handles missing return values.
/// @author Modified from SolMate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// License-Identifier: AGPL-3.0-only
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error ETHtransferFailed();

    error TransferFailed();

    error TransferFromFailed();

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function _safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // transfer the ETH and store if it succeeded or not
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!callStatus) revert ETHtransferFailed();
    }

    /*///////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // get a pointer to some free memory
            let freeMemoryPointer := mload(0x40)

            // write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // begin with the function selector
            
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "to" argument
            
            mstore(add(freeMemoryPointer, 36), amount) // finally append the "amount" argument - no mask as it's a full 32 byte value

            // call the token and store if it succeeded or not
            // we use 68 because the calldata length is 4 + 32 * 2
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        if (!_didLastOptionalReturnCallSucceed(callStatus)) revert TransferFailed();
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // get a pointer to some free memory
            let freeMemoryPointer := mload(0x40)

            // write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // begin with the function selector
            
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "from" argument
            
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "to" argument
            
            mstore(add(freeMemoryPointer, 68), amount) // finally append the "amount" argument - no mask as it's a full 32 byte value

            // call the token and store if it succeeded or not
            // we use 100 because the calldata length is 4 + 32 * 3
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        if (!_didLastOptionalReturnCallSucceed(callStatus)) revert TransferFromFailed();
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function _didLastOptionalReturnCallSucceed(bool callStatus) internal pure returns (bool success) {
        assembly {
            // get how many bytes the call returned
            let returnDataSize := returndatasize()

            // if the call reverted:
            if iszero(callStatus) {
                // copy the revert message into memory
                returndatacopy(0, 0, returnDataSize)

                // revert with the same message
                revert(0, returnDataSize)
            }

            switch returnDataSize
            
            case 32 {
                // copy the return data into memory
                returndatacopy(0, 0, returnDataSize)

                // set success to whether it returned true
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // there was no return data
                success := 1
            }
            default {
                // it returned some malformed input
                success := 0
            }
        }
    }
}

/// @notice Kali DAO tribute escrow interface.
interface IKaliDAOtribute {
    enum ProposalType {
        MINT, 
        BURN, 
        CALL, 
        VPERIOD,
        GPERIOD, 
        QUORUM, 
        SUPERMAJORITY, 
        TYPE, 
        PAUSE, 
        EXTENSION,
        ESCAPE,
        DOCS
    }

    struct ProposalState {
        bool passed;
        bool processed;
    }

    function proposalStates(uint256 proposal) external view returns (ProposalState memory);

    function propose(
        ProposalType proposalType,
        string calldata description,
        address[] calldata accounts,
        uint256[] calldata amounts,
        bytes[] calldata payloads
    ) external returns (uint256 proposal);

    function cancelProposal(uint256 proposal) external;

    function processProposal(uint256 proposal) external returns (bool didProposalPass, bytes[] memory results);
}

/// @notice Helper utility that enables calling multiple local methods in a single call.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract Multicall {
    function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);

                if (!success) {
                    if (result.length < 68) revert();
                    
                    assembly {
                        result := add(result, 0x04)
                    }
                    
                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }
}

/// @notice Gas-optimized reentrancy protection.
/// @author Modified from OpenZeppelin 
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
/// License-Identifier: MIT
abstract contract ReentrancyGuard {
    error Reentrancy();

    uint256 private constant NOT_ENTERED = 1;

    uint256 private constant ENTERED = 2;

    uint256 private status = NOT_ENTERED;

    modifier nonReentrant() {
        if (status == ENTERED) revert Reentrancy();

        status = ENTERED;

        _;

        status = NOT_ENTERED;
    }
}

/// @notice Tribute contract that escrows ETH, ERC-20 or NFT for Kali DAO proposals.
contract KaliDAOtribute is Multicall, ReentrancyGuard {
    using SafeTransferLib for address;

    event NewTributeProposal(
        IKaliDAOtribute indexed dao,
        address indexed proposer, 
        uint256 indexed proposal, 
        address asset, 
        bool nft,
        uint256 value
    );

    event TributeProposalCancelled(IKaliDAOtribute indexed dao, uint256 indexed proposal);

    event TributeProposalReleased(IKaliDAOtribute indexed dao, uint256 indexed proposal);
    
    error NotProposer();

    error Sponsored(); 

    error NotProposal();

    error NotProcessed();

    mapping(IKaliDAOtribute => mapping(uint256 => Tribute)) public tributes;

    struct Tribute {
        address proposer;
        address asset;
        bool nft;
        uint256 value;
    }

    function submitTributeProposal(
        IKaliDAOtribute dao,
        IKaliDAOtribute.ProposalType proposalType, 
        string memory description,
        address[] calldata accounts,
        uint256[] calldata amounts,
        bytes[] calldata payloads,
        bool nft,
        address asset, 
        uint256 value
    ) public payable nonReentrant virtual {
        // escrow tribute
        if (msg.value != 0) {
            asset = address(0);
            value = msg.value;
            if (nft) nft = false;
        } else {
            asset._safeTransferFrom(msg.sender, address(this), value);
        }

        uint256 proposal = dao.propose(
            proposalType,
            description,
            accounts,
            amounts,
            payloads
        );

        tributes[dao][proposal] = Tribute({
            proposer: msg.sender,
            asset: asset,
            nft: nft,
            value: value
        });

        emit NewTributeProposal(dao, msg.sender, proposal, asset, nft, value);
    }

    function cancelTributeProposal(IKaliDAOtribute dao, uint256 proposal) public nonReentrant virtual {
        Tribute storage trib = tributes[dao][proposal];

        if (msg.sender != trib.proposer) revert NotProposer();

        dao.cancelProposal(proposal);

        // return tribute from escrow
        if (trib.asset == address(0)) {
            trib.proposer._safeTransferETH(trib.value);
        } else if (!trib.nft) {
            trib.asset._safeTransfer(trib.proposer, trib.value);
        } else {
            trib.asset._safeTransferFrom(address(this), trib.proposer, trib.value);
        }
        
        delete tributes[dao][proposal];

        emit TributeProposalCancelled(dao, proposal);
    }

    function releaseTributeProposalAndProcess(IKaliDAOtribute dao, uint256 proposal) public virtual {
        dao.processProposal(proposal);

        releaseTributeProposal(dao, proposal);
    }

    function releaseTributeProposal(IKaliDAOtribute dao, uint256 proposal) public nonReentrant virtual {
        Tribute storage trib = tributes[dao][proposal];

        if (trib.proposer == address(0)) revert NotProposal();
        
        IKaliDAOtribute.ProposalState memory prop = dao.proposalStates(proposal);

        if (!prop.processed) revert NotProcessed();

        // release tribute from escrow based on proposal outcome
        if (prop.passed) {
            if (trib.asset == address(0)) {
                address(dao)._safeTransferETH(trib.value);
            } else if (!trib.nft) {
                trib.asset._safeTransfer(address(dao), trib.value);
            } else {
                trib.asset._safeTransferFrom(address(this), address(dao), trib.value);
            }
        } else {
            if (trib.asset == address(0)) {
                trib.proposer._safeTransferETH(trib.value);
            } else if (!trib.nft) {
                trib.asset._safeTransfer(trib.proposer, trib.value);
            } else {
                trib.asset._safeTransferFrom(address(this), trib.proposer, trib.value);
            }
        }

        delete tributes[dao][proposal];

        emit TributeProposalReleased(dao, proposal);
    }
}