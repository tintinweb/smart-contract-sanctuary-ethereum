// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./ISimpleToken.sol";
import "./IMrGreedyToken.sol";
import "./IContractsHaterToken.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Empty {}

contract Validator {
    address constant randomAddress1 = 0xa000000000000000000000000000000000000000;
    address constant randomAddress2 = 0xB000000000000000000000000000000000000000;
    address constant randomAddress3 = 0xC000000000000000000000000000000000000000;

    function validate(
        address simple_,
        address contractsHater_,
        address mrGreedy_
    ) external returns (bool) {
        // metadata validation
        _validateMetadata(simple_, contractsHater_, mrGreedy_);

        // mint/burn validation
        _validateMintBurn(simple_, "SimpleToken");
        _validateMintBurn(contractsHater_, "ContractsHaterToken");
        _validateMintBurn(mrGreedy_, "MrGreedyToken");

        // ContractsHaterToken validation
        _validateContractsHater(contractsHater_);

        // MrGreedyToken validation
        _validateMrGreedy(mrGreedy_);

        return true;
    }

    function _validateMetadata(
        address simple_,
        address contractsHater_,
        address mrGreedy_
    ) private {
        require(
            keccak256(bytes(IERC20Metadata(simple_).name())) == keccak256(bytes("SimpleToken")),
            "Validator: wrong SimpleToken name"
        );
        require(
            keccak256(bytes(IERC20Metadata(simple_).symbol())) == keccak256(bytes("ST")),
            "Validator: wrong SimpleToken symbol"
        );
        require(IERC20Metadata(simple_).decimals() == 18, "SimpleToke: wrong decimals");

        require(
            keccak256(bytes(IERC20Metadata(contractsHater_).name())) ==
                keccak256(bytes("ContractsHaterToken")),
            "Validator: wrong contractsHater name"
        );
        require(
            keccak256(bytes(IERC20Metadata(contractsHater_).symbol())) == keccak256(bytes("CHT")),
            "Validator: wrong contractsHater symbol"
        );
        require(
            IERC20Metadata(contractsHater_).decimals() == 18,
            "Validator: wrong contractsHater decimals"
        );

        require(
            keccak256(bytes(IERC20Metadata(mrGreedy_).name())) ==
                keccak256(bytes("MrGreedyToken")),
            "Validator: wrong mrGreedy name"
        );
        require(
            keccak256(bytes(IERC20Metadata(mrGreedy_).symbol())) == keccak256(bytes("MRG")),
            "Validator: wrong mrGreedy symbol"
        );
        require(IERC20Metadata(mrGreedy_).decimals() == 6, "Validator: wrong mrGreedy decimals");
    }

    function _validateMintBurn(address contract_, string memory name_) private {
        ISimpleToken(contract_).mint(address(this), 100);
        ISimpleToken(contract_).mint(randomAddress1, 55);
        require(
            IERC20(contract_).balanceOf(address(this)) == 100,
            string(abi.encodePacked("Validator: in ", name_, " mint function failed"))
        );
        require(
            IERC20(contract_).balanceOf(randomAddress1) == 55,
            string(abi.encodePacked("Validator: in ", name_, " mint function failed"))
        );

        ISimpleToken(contract_).burn(50);
        require(
            IERC20(contract_).balanceOf(address(this)) == 50,
            string(abi.encodePacked("Validator: in ", name_, " burn function failed"))
        );
        ISimpleToken(contract_).burn(50);
        require(
            IERC20(contract_).balanceOf(address(this)) == 0,
            string(abi.encodePacked("Validator: in ", name_, " burn function failed"))
        );
    }

    function _validateContractsHater(address contractsHater_) private {
        address empty1_ = address(new Empty());
        address empty2_ = address(new Empty());

        ISimpleToken(contractsHater_).mint(address(this), 100);
        IERC20(contractsHater_).transfer(randomAddress2, 21);

        require(
            IERC20(contractsHater_).balanceOf(address(this)) == 79,
            "Validator: transfer at ContractsHaterToken failed"
        );
        require(
            IERC20(contractsHater_).balanceOf(randomAddress2) == 21,
            "Validator: transfer at ContractsHaterToken failed"
        );

        bytes memory transferCall1_ = abi.encodeWithSignature(
            "transfer(address,uint256)",
            empty1_,
            10
        );
        (bool success1_, ) = contractsHater_.call(transferCall1_);
        require(
            !success1_,
            "Validator: transfer to non whitlisted contract passed in contractsHaterToken"
        );

        IContractsHaterToken(contractsHater_).addToWhitelist(empty2_);
        IERC20(contractsHater_).transfer(empty2_, 22);
        require(
            IERC20(contractsHater_).balanceOf(address(this)) == 57,
            "Validator: transfer to whitlisted contract address at ContractsHaterToken failed"
        );
        require(
            IERC20(contractsHater_).balanceOf(empty2_) == 22,
            "Validator: transfer to whitlisted contract address at ContractsHaterToken failed"
        );

        IContractsHaterToken(contractsHater_).removeFromWhitelist(empty2_);
        bytes memory transferCall2_ = abi.encodeWithSignature(
            "transfer(address,uint256)",
            empty2_,
            10
        );
        (bool success2_, ) = contractsHater_.call(transferCall2_);
        require(
            !success2_,
            "Validator: transfer to contract that was removed from whitelist passed in contractsHaterToken"
        );
    }

    function _validateMrGreedy(address mrGreedy_) private {
        uint256 oneToken_ = 10**6;
        ISimpleToken(mrGreedy_).mint(address(this), 100 * oneToken_);
        IERC20(mrGreedy_).transfer(randomAddress3, 97 * oneToken_);

        require(
            IERC20(mrGreedy_).balanceOf(address(this)) == 3 * oneToken_,
            "Validator: transfer at MrGreedyToken failed"
        );
        require(
            IERC20(mrGreedy_).balanceOf(randomAddress3) == 87 * oneToken_,
            "Validator: transfer at MrGreedyToken failed"
        );
        address treasury_ = IMrGreedyToken(mrGreedy_).treasury();
        require(
            IERC20(mrGreedy_).balanceOf(treasury_) == 10 * oneToken_,
            "Validator: transfer at MrGreedyToken failed"
        );

        IERC20(mrGreedy_).transfer(randomAddress3, 3 * oneToken_);
        require(
            IERC20(mrGreedy_).balanceOf(address(this)) == 0,
            "Validator: transfer at MrGreedyToken failed"
        );
        require(
            IERC20(mrGreedy_).balanceOf(treasury_) == 13 * oneToken_,
            "Validator: transfer at MrGreedyToken failed"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface ISimpleToken {
    function mint(address to_, uint256 amount_) external;

    function burn(uint256 amount_) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IMrGreedyToken {
    function treasury() external view returns (address);

    function getResultingTransferAmount(uint256 amount_) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IContractsHaterToken {
    function addToWhitelist(address candidate_) external;

    function removeFromWhitelist(address candidate_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}