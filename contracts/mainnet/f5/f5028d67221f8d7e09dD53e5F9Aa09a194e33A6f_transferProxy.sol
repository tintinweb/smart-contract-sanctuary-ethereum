// SPDX-License-Identifier: MiladyCometh
pragma solidity ^0.8.17;

/// @author lcfr.eth
/// @notice helper contract for Flashbots rescues using bundler.lcfr.io

/// @dev avoids using freememptr to avoid unnecessily calling add() in loops etc
/// @dev this is fine as our functions execution are short & sweet.
/// @dev for transferFrom calls the calldata is 0x64 bytes which is the size of the scratch space.

/// @dev however for ERC1155 safeTransferFrom calls the calldata is 0xc4 bytes which is larger than the scratch space.
/// @dev we dont care tho - smash all the memory like its a stack based buffer and the year is 1992AD and your name is aleph1.

/// @dev We dont call any other internal / contract methods and only perform external calls:
/// @dev No hash functions are used in our function executions so we dont need to care about 0x00 - 0x3f
/// @dev No dynamic memory is used in our function executions so we dont need to care about 0x40 - 0x5f
/// @dev No operations requiring the zero slot so we just plow through 0x60-0x7f+ also

contract transferProxy {
    // 0x383462e2 == "notApproved()"
    error notApproved();
    // 0x543bf3c4 == "arrayLengthMismatch()"
    error arrayLengthMismatch();

    // transfers a batch of ERC721 tokens to a single address recipient from an approved caller address
    function approvedTransferERC721(uint256[] calldata tokenIds, address _contract, address _from, address _to) external {
        assembly {
            // check if caller isApprovedForAll() by _from on _contract or revert
            mstore(0x00, 0xe985e9c5ac1db17cac1db17cac1db17cac1db17cac1db17cac1db17cac1db17c)
            // store _from as the first parameter to isApprovedForAll()
            mstore(0x04, _from) 
            // store caller as the second parameter to isApprovedForAll()
            mstore(0x24, caller())
            // call _contract.isApprovedForAll(_from, caller())
            let success := staticcall(gas(), _contract, 0x00, 0x44, 0x00, 0x00)
            // copy return data to 0x00 
            returndatacopy(0x00, 0x00, returndatasize())
            // revert if the call was not successful
            if iszero(success) {
                revert(0x00, returndatasize())
            }
            // check if the return data is 0x01 (true) or revert
            if iszero(mload(0x00)) {
                mstore(0x00, 0x383462e2)
                revert(0x1c, 0x04)
            }

            // build calldata using the _from and _to thats supplied as an argument
            // transferFrom(address,address,uint256) selector
            // store the selector at 0x00
            mstore(0x00, 0x23b872ddac1db17cac1db17cac1db17cac1db17cac1db17cac1db17cac1db17c)
            // store the caller as the first parameter to transferFrom()
            mstore(0x04, _from)
            // store _to as the second parameter to transferFrom()
            mstore(0x24, _to)

            // start our loop at 0
            let i := 0
            for {} 1 { i:= add(i, 1) } {
                // check if we have reached the end of the array. _data len starts at 1
                if eq(i, tokenIds.length){ break }

                // copy the token id as the third parameter to transferFrom()
                calldatacopy(0x44, add(tokenIds.offset, shl(5, i)), 0x20)

                // call the encoded method        
                success := call( gas(), _contract, 0x00, 0x00, 0x64, 0x00, 0x00)

                if iszero(success) {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
            }
        }
    }

    /// @notice transfer assets from the owner to the _to address
    function ownerTransferERC721(uint256[] calldata tokenIds, address _to, address _contract) external {
        assembly {
            // transferFrom(address,address,uint256) selector
            // store the selector at 0x00
            mstore(0x00, 0x23b872ddac1db17cac1db17cac1db17cac1db17cac1db17cac1db17cac1db17c)
            // store the caller as the first parameter to transferFrom()
            mstore(0x04, caller())
            // store _to as the second parameter to transferFrom()
            mstore(0x24, _to)

             let i := 0
             for {} 1 { i:= add(i, 1) } {
                if eq(i, tokenIds.length){ break }

                // copy the token id as the third parameter to transferFrom()
                calldatacopy(0x44, add(tokenIds.offset, shl(5, i)), 0x20)
                
                // call transferFrom
                let success := call( gas(), _contract, 0x00, 0x00, 0x64, 0x00, 0x00)

                if iszero(success) {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
            }
        }
    }

    /// @notice intended for transferring an array of tokens to an array of addresses from the owner
    function ownerAirDropERC721(uint256[] calldata tokenIds, address[] calldata _addrs, address _contract) external {
        assembly {
            // check if the arrays are the same length
            if iszero(eq(tokenIds.length, _addrs.length)) {
                mstore(0x00, 0x543bf3c4)
                revert(0x1c, 0x04)
            }
            // transferFrom(address,address,uint256) selector
            // store the selector at 0x00
            mstore(0x00, 0x23b872ddac1db17cac1db17cac1db17cac1db17cac1db17cac1db17cac1db17c)
            // store the caller as the first parameter to transferFrom()
            mstore(0x04, caller())

             let i := 0
             for {} 1 { i:= add(i, 1) } {
                if eq(i, tokenIds.length){ break }

                // offset for both arrays
                let offset := shl(5, i)

                // copy the address to send to as the second parameter to transferFrom()
                calldatacopy(0x24, add(_addrs.offset, offset), 0x20)

                // copy the token id as the third parameter to transferFrom()
                calldatacopy(0x44, add(tokenIds.offset, offset), 0x20)
                
                // call transferFrom
                let success := call( gas(), _contract, 0x00, 0x00, 0x64, 0x00, 0x00)

                if iszero(success) {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
            }
        }
    }

    // we just smash all the memory from 0x00 - 0xC4 like its a stack based buffer and the year is 1992.
    function ownerAirDropERC1155(uint256[] calldata _tokenIds, uint256[] calldata _amounts, address[] calldata _addrs, address _contract) external {
        assembly {

            // check if all 3 the arrays are the same length
            let lenCheck := eq(_tokenIds.length, _amounts.length)
            lenCheck := and(lenCheck, eq(_amounts.length, _addrs.length))

            if iszero(lenCheck) {
                mstore(0x00, 0x543bf3c4)
                revert(0x1c, 0x04)
            }

            // ERC1155 safeTransferFrom(address,address,uint256,uint256,bytes)

            // store the selector at 0x00
            mstore(0x00, 0xf242432aac1db17cac1db17cac1db17cac1db17cac1db17cac1db17cac1db17c)
            // store the caller as the first parameter to safeTransferFrom()
            mstore(0x04, caller())

             let i := 0
             for {} 1 { i:= add(i, 1) } {
                if eq(i, _tokenIds.length){ break }

                // offset for both arrays
                let offset := shl(5, i)

                // copy the address to send to as the second parameter
                calldatacopy(0x24, add(_addrs.offset, offset), 0x20)

                // copy the token id as the third parameter
                calldatacopy(0x44, add(_tokenIds.offset, offset), 0x20)

                // copy the amount as the fourth parameter
                calldatacopy(0x64, add(_amounts.offset, offset), 0x20)

                // create an empty bytes and copy it as the fifth parameter
                mstore(0x84, 0xa0)
                mstore(0xa4, 0x00)

                // call safeTransferFrom
                let success := call( gas(), _contract, 0x00, 0x00, 0xc4, 0x00, 0x00 )

                if iszero(success) {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
            }
        }

    }

    // ApprovedTransferERC1155 can be done via the ERC1155 safeBatchTransferFrom() function in the UI
    // OwnerTransferERC1155 can be done via the ERC1155 safeBatchTransferFrom() function in the UI
}