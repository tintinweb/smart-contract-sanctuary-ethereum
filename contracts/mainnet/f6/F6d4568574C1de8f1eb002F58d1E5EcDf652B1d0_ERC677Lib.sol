/* SPDX-License-Identifier: apache-2.0 */
/**
 * Copyright 2022 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.8.11;

import "./Address.sol";
import "./IERC677Recipient.sol";
import "./TokenStorage.sol";
import "./ERC20Lib.sol";

/**
 * @title ERC677
 * @dev ERC677 token functionality.
 * https://github.com/ethereum/EIPs/issues/677
 */
library ERC677Lib {

    using ERC20Lib for TokenStorage;
    using Address for address;

    /**
     * @dev Transfers tokens and subsequently calls a method on the recipient [ERC677].
     * If the recipient is a non-contract address this method behaves just like transfer.
     * @notice db.transfer either returns true or reverts.
     * @param db Token storage to operate on.
     * @param caller Address of the caller passed through the frontend.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     * @param data Additional data passed to the recipient's tokenFallback method.
     */
    function transferAndCall(
        TokenStorage db,
        address caller,
        address to,
        uint256 amount,
        bytes calldata data
    )
        external
        returns (bool)
    {
        require(
            db.transfer(caller, to, amount), 
            "unable to transfer"
        );
        if (to.isContract()) {
            IERC677Recipient recipient = IERC677Recipient(to);
            require(
                recipient.onTokenTransfer(caller, amount, data),
                "token handler returns false"
            );
        }
        return true;
    }

}