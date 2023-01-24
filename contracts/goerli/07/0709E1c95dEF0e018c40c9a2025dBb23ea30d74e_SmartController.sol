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

import "./SmartTokenLib.sol";
import "./MintableController.sol";
import "./IValidator.sol";

/**
 * @title SmartController
 * @dev This contract adds "smart" functionality which is required from a regulatory perspective.
 */
contract SmartController is MintableController {

    using SmartTokenLib for SmartTokenLib.SmartStorage;

    SmartTokenLib.SmartStorage internal smartToken;

    bytes3 public ticker;
    uint constant public INITIAL_SUPPLY = 0;

    /**
     * @dev Contract constructor.
     * @param storage_ Address of the token storage for the controller.
     * @param validator Address of validator.
     * @param ticker_ 3 letter currency ticker.
     * @param frontend_ Address of the authorized frontend.
     */
    constructor(address storage_, address validator, bytes3 ticker_, address frontend_)
        MintableController(storage_, INITIAL_SUPPLY, frontend_)
    {
        require(validator != address(0x0), "validator cannot be the null address");
        smartToken.setValidator(validator);
        ticker = ticker_;
    }

    /**
     * @dev Sets a new validator.
     * @param validator Address of validator.
     */
    function setValidator(address validator) external onlySystemAccounts {
        smartToken.setValidator(validator);
    }

    /**
     * @dev Recovers tokens from an address and reissues them to another address.
     * In case a user loses its private key the tokens can be recovered by burning
     * the tokens from that address and reissuing to a new address.
     * To recover tokens the contract owner needs to provide a signature
     * proving that the token owner has authorized the owner to do so.
     * @param caller Address of the caller passed through the frontend.
     * @param from Address to burn tokens from.
     * @param to Address to mint tokens to.
     * @param h Hash which the token owner signed.
     * @param v Signature component.
     * @param r Signature component.
     * @param s Sigature component.
     * @return Amount recovered.
     */
    function recover_withCaller(address caller, address from, address to, bytes32 h, uint8 v, bytes32 r, bytes32 s)
        external
        guarded(caller)
        onlySystemAccount(caller)
        returns (uint)
    {
        avoidBlackholes(to);
        return SmartTokenLib.recover(token, from, to, h, v, r, s);
    }

    /**
     * @dev Transfers tokens [ERC20].
     * The caller, to address and amount are validated before executing method.
     * Prior to transfering tokens the validator needs to approve.
     * @notice Overrides method in a parent.
     * @param caller Address of the caller passed through the frontend.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transfer_withCaller(address caller, address to, uint amount)
        public
        override
        guarded(caller)
        whenNotPaused
        returns (bool)
    {
        require(smartToken.validate(caller, to, amount), "transfer request not valid");
        return super.transfer_withCaller(caller, to, amount);
    }

    /**
     * @dev Transfers tokens from a specific address [ERC20].
     * The address owner has to approve the spender beforehand.
     * The from address, to address and amount are validated before executing method.
     * @notice Overrides method in a parent.
     * Prior to transfering tokens the validator needs to approve.
     * @param caller Address of the caller passed through the frontend.
     * @param from Address to debet the tokens from.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transferFrom_withCaller(address caller, address from, address to, uint amount)
        public
        override
        guarded(caller)
        whenNotPaused
        returns (bool)
    {
        require(smartToken.validate(from, to, amount), "transferFrom request not valid");
        return super.transferFrom_withCaller(caller, from, to, amount);
    }

    /**
     * @dev Transfers tokens and subsequently calls a method on the recipient [ERC677].
     * If the recipient is a non-contract address this method behaves just like transfer.
     * The caller, to address and amount are validated before executing method.
     * @notice Overrides method in a parent.
     * @param caller Address of the caller passed through the frontend.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     * @param data Additional data passed to the recipient's tokenFallback method.
     */
    function transferAndCall_withCaller(
        address caller,
        address to,
        uint256 amount,
        bytes calldata data
    )
        public
        override
        guarded(caller)
        whenNotPaused
        returns (bool)
    {
        require(smartToken.validate(caller, to, amount), "transferAndCall request not valid");
        return super.transferAndCall_withCaller(caller, to, amount, data);
    }

    /**
     * @dev Gets the current validator.
     * @return Address of validator.
     */
    function getValidator() external view returns (address) {
        return smartToken.getValidator();
    }

}