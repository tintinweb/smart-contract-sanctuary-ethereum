// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20X/ERC20X.sol";

/// ERC-20 that can be held by a token
contract SpellsCoin is ERC20X, Ownable {
    address minter;
    uint256 private claimable;

    constructor(address _minter, uint256 _claimable) ERC20X("Spells Magic", "CAST") {
        minter = _minter;
        claimable = _claimable;
    }
    
    function claim() external onlyOwner nonReentrant {
        require(claimable > 0, "SpellsCoin: no claimabled remaining");
        _mint(owner(), claimable);
        claimable = 0;
    }
    
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }
    
    function setName(string memory name_, string memory symbol_) external onlyOwner {
        _name = name_;
        symbol_ = symbol_;
    }

    function decimals() public pure override(ERC20) returns (uint8) {
        return 18;
    }

    /// @dev Spells contract can mint spellsCoin to given `tokenId`.
    function mint(
        address _contract,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(msg.sender == minter, "SpellsCoin: sender not minter");
        _mint(_contract, tokenId, amount);
    }
    
    /// @dev Spells contract can mint spellsCoin to given address.
    function mint(address account, uint256 amount) external {
        require(msg.sender == minter, "SpellsCoin: sender not minter");
        _mint(account, amount);
    }
}

pragma solidity ^0.8.6;

library ECDSA {
    /*
     * @dev Verifies if message was signed by owner to give access to _add for this contract.
     *      Assumes Geth signature prefix.
     * @param _add Address of agent with access
     * @param _v ECDSA signature parameter v.
     * @param _r ECDSA signature parameters r.
     * @param _s ECDSA signature parameters s.
     * @return Validity of access message for a given address.
     */
    function isValidAccessMessage(
        address expectedSigner,
        bytes32 _hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (bool) {
        return
            expectedSigner ==
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
                ),
                _v,
                _r,
                _s
            );
    }
}

// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20X is IERC20 {
    function totalTokenHeldSupply() external view returns (uint256);

    function balanceOf(address _contract, uint256 tokenId)
        external
        view
        returns (uint256);

    function nonce(address _contract, uint256 tokenId)
        external
        view
        returns (uint256);

    function transfer(
        address _contract,
        uint256 tokenId,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address _contract,
        uint256 tokenId,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address _contract,
        uint256 tokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address from,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address _contract,
        uint256 tokenId,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address _contract,
        uint256 tokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) external returns (bool);

    function approve(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _contract,
        uint256 tokenId,
        address spender
    ) external view returns (uint256);

    function allowance(
        address tokenOwner,
        address _contract,
        uint256 tokenId,
        address spender
    ) external view returns (uint256);

    function increaseAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function decreaseAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function signedTransferFrom(
        DynamicAddress memory from,
        DynamicAddress memory to,
        uint256 amount,
        uint256 nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event XTransfer(
        address indexed from,
        uint256 fromTokenId,
        address indexed to,
        uint256 toTokenId,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event XApproval(
        address indexed _contract,
        uint256 tokenId,
        address indexed spender,
        uint256 value
    );
}

/// @param _address The address of the entity
/// @param _tokenId The token of the object (optional)
/// @param _useZeroToken Treat tokenId 0 as a token (default: ignore tokenId 0)
struct DynamicAddress {
    address _address;
    uint256 _tokenId;
    bool _useZeroToken;
}

library DynamicAddressLib {
    using Address for address;
    
    function isToken(DynamicAddress memory _address) internal view returns (bool) {
        return (_address._address.isContract() && (_address._tokenId > 0 || _address._useZeroToken));
    }
}

// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC20.sol";
import "./IERC20X.sol";
import "../../helpers/ECDSA.sol";

interface _IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title ERC-20 that can be held by NFTs
contract ERC20X is IERC20X, ERC20, ReentrancyGuard {
    using Address for address;
    using DynamicAddressLib for DynamicAddress;
    // when spell is cast, set amount of spellsCoin claimable by recipient contract

    mapping(address => mapping(uint256 => uint256)) internal _tokenBalances;
    mapping(address => mapping(uint256 => uint256)) public _nonces;
    mapping(address => uint256) public _addressNonces;

    // tokenOwner : tokenContract : tokenId : spender : amount
    mapping(address => mapping(address => mapping(uint256 => mapping(address => uint256))))
        private _tokenAllowances;
    uint256 _totalTokenHeldSupply;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function balanceOf(address _contract, uint256 tokenId)
        external
        view
        override(IERC20X)
        returns (uint256)
    {
        return _tokenBalances[_contract][tokenId];
    }

    function totalTokenHeldSupply() public view virtual override(IERC20X) returns (uint256) {
        return _totalTokenHeldSupply;
    }

    function nonce(address _contract, uint256 tokenId)
        external
        view
        override(IERC20X)
        returns (uint256)
    {
        return _nonces[_contract][tokenId];
    }
    
    function nonce(address _address)
        external
        view
        returns (uint256)
    {
        return _addressNonces[_address];
    }

    function incrementNonce(address _contract, uint256 tokenId) external {
        address owner = _ownerOf(_contract, tokenId);
        require(msg.sender == owner, "SpellsCoin: Invalid withdrawal");
        _nonces[_contract][tokenId]++;
    }

    function transfer(
        address _contract,
        uint256 tokenId,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _msgSender();
        _transfer(owner, _contract, tokenId, amount);
        return true;
    }

    function transfer(
        address _contract,
        uint256 tokenId,
        address to,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _ownerOf(_contract, tokenId);
        require(
            msg.sender == owner,
            "SpellsCoin: transfer not initiated by token owner"
        );
        _transfer(_contract, tokenId, to, amount);
        return true;
    }

    function transfer(
        address _contract,
        uint256 tokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _ownerOf(_contract, tokenId);
        require(
            msg.sender == owner,
            "SpellsCoin: transfer not initiated by token owner"
        );
        _transfer(_contract, tokenId, toContract, toTokenId, amount);
        return true;
    }

    function transferFrom(
        address from,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, toContract, toTokenId, amount);
        return true;
    }

    function transferFrom(
        address _contract,
        uint256 tokenId,
        address to,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(_contract, tokenId, spender, amount);
        _transfer(_contract, tokenId, to, amount);
        return true;
    }

    function transferFrom(
        address _contract,
        uint256 tokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(_contract, tokenId, spender, amount);
        _transfer(_contract, tokenId, toContract, toTokenId, amount);
        return true;
    }

    function _transfer(
        address from,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "SpellsCoin: transfer from the zero address");
        require(toContract != address(0), "SpellsCoin: transfer to the zero token");

        _beforeTokenTransfer(from, toContract, toTokenId, amount);

        _transfer(from, address(this), amount);
        _totalTokenHeldSupply += amount;
        _tokenBalances[toContract][toTokenId] += amount;

        emit XTransfer(from, type(uint256).max, toContract, toTokenId, amount);

        _afterTokenTransfer(from, toContract, toTokenId, amount);
    }

    function _transfer(
        address fromContract,
        uint256 fromTokenId,
        address to,
        uint256 amount
    ) internal virtual {
        require(
            fromContract != address(0),
            "SpellsCoin: transfer from the zero address"
        );
        require(to != address(0), "SpellsCoin: transfer to the zero address");

        _beforeTokenTransfer(fromContract, fromTokenId, to, amount);

        uint256 fromBalance = _tokenBalances[fromContract][fromTokenId];
        require(fromBalance >= amount, "SpellsCoin: transfer amount exceeds balance");
        unchecked {
            _tokenBalances[fromContract][fromTokenId] = fromBalance - amount;
            _totalTokenHeldSupply -= amount;
        }
        // do underlying token transfer
        _transfer(address(this), to, amount);

        emit XTransfer(
            fromContract,
            fromTokenId,
            to,
            type(uint256).max,
            amount
        );

        _afterTokenTransfer(fromContract, fromTokenId, to, amount);
    }

    function _transfer(
        address fromContract,
        uint256 fromTokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {
        require(
            fromContract != address(0),
            "SpellsCoin: transfer from the zero address"
        );
        require(toContract != address(0), "SpellsCoin: transfer to the zero address");
        _beforeTokenTransfer(
            fromContract,
            fromTokenId,
            toContract,
            toTokenId,
            amount
        );
        uint256 fromBalance = _tokenBalances[fromContract][fromTokenId];
        require(fromBalance >= amount, "SpellsCoin: transfer amount exceeds balance");
        unchecked {
            _tokenBalances[fromContract][fromTokenId] = fromBalance - amount;
        }
        _tokenBalances[toContract][toTokenId] += amount;

        emit XTransfer(
            fromContract,
            fromTokenId,
            toContract,
            toTokenId,
            amount
        );
        _afterTokenTransfer(
            fromContract,
            fromTokenId,
            toContract,
            toTokenId,
            amount
        );
    }
    
    function _transfer(
        DynamicAddress memory from,
        DynamicAddress memory to,
        uint256 amount
    ) internal virtual {
        require(from._address != address(0), "ERC20X: transfer from the zero address");
        require(to._address != address(0), "ERC20X: transfer to the zero address");
         if(from.isToken()){
            if(to.isToken()){
                _transfer(from._address, from._tokenId, to._address, to._tokenId, amount);
            } else {
                _transfer(from._address, from._tokenId, to._address, amount);
            }
        } else if(to.isToken()){
            _transfer(from._address, to._address, to._tokenId, amount);
        } else {
            _transfer(from._address, to._address, amount);
        }
    }

    function _mint(
        address _contract,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(_contract != address(0), "SpellsCoin: mint to the zero address");
        _beforeTokenTransfer(address(0), _contract, tokenId, amount);

        _tokenBalances[_contract][tokenId] += amount;
        _totalTokenHeldSupply += amount;
    
        // mint token to self in ERC20 standard contract
        _mint(address(this), amount);
        emit XTransfer(
            address(0),
            type(uint256).max,
            _contract,
            tokenId,
            amount
        );

        _afterTokenTransfer(address(0), _contract, tokenId, amount);
    }

    function increaseAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 addedValue
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _ownerOf(_contract, tokenId);
        require(
            msg.sender == owner,
            "SpellsCoin: allowance change not initiated by token owner"
        );
        _approve(
            _contract,
            tokenId,
            spender,
            allowance(owner, _contract, tokenId, spender) + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 subtractedValue
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _ownerOf(_contract, tokenId);
        require(
            msg.sender == owner,
            "SpellsCoin: allowance change not initiated by token owner"
        );
        uint256 currentAllowance = allowance(
            owner,
            _contract,
            tokenId,
            spender
        );
        require(
            currentAllowance >= subtractedValue,
            "SpellsCoin: decreased allowance below zero"
        );
        unchecked {
            _approve(
                _contract,
                tokenId,
                spender,
                currentAllowance - subtractedValue
            );
        }
        return true;
    }

    function allowance(
        address _contract,
        uint256 tokenId,
        address spender
    ) public view virtual override(IERC20X) returns (uint256) {
        return
            _tokenAllowances[_ownerOf(_contract, tokenId)][_contract][tokenId][
                spender
            ];
    }

    function allowance(
        address tokenOwner,
        address _contract,
        uint256 tokenId,
        address spender
    ) public view virtual override(IERC20X) returns (uint256) {
        return _tokenAllowances[tokenOwner][_contract][tokenId][spender];
    }

    function approve(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 amount
    ) public virtual override(IERC20X) returns (bool) {
        address owner = _ownerOf(_contract, tokenId);
        require(
            msg.sender == owner,
            "SpellsCoin: approve not initiated by token owner"
        );
        _approve(_contract, tokenId, spender, amount);
        return true;
    }

    function _approve(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 amount
    ) internal virtual {
        require(_contract != address(0), "SpellsCoin: approve from the zero address");
        require(spender != address(0), "SpellsCoin: approve to the zero address");
        _tokenAllowances[msg.sender][_contract][tokenId][spender] = amount;
        emit XApproval(_contract, tokenId, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _spendAllowance(
        address _contract,
        uint256 tokenId,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(_contract, tokenId, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "SpellsCoin: insufficient allowance");
            unchecked {
                _approve(
                    _contract,
                    tokenId,
                    spender,
                    currentAllowance - amount
                );
            }
        }
    }

    function _beforeTokenTransfer(
        address fromContract,
        uint256 fromTokenId,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address fromContract,
        uint256 fromTokenId,
        address to,
        uint256 amount
    ) internal virtual {}

    function _beforeTokenTransfer(
        address from,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {}

    function _beforeTokenTransfer(
        address fromContract,
        uint256 fromTokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address fromContract,
        uint256 fromTokenId,
        address toContract,
        uint256 toTokenId,
        uint256 amount
    ) internal virtual {}
    
    function signedTransferFrom(
        DynamicAddress calldata from,
        DynamicAddress calldata to,
        uint256 amount,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override(IERC20X) {
        require(
            from._address != address(0),
            "SpellsCoin: transfer from the zero address"
        );
        require(
            to._address != address(0),
            "SpellsCoin: transfer to the zero address"
        );
        address signer = from._address;
        if (from._address.isContract()){
            if(from._tokenId > 0 || from._useZeroToken){
                signer = _ownerOf(from._address, from._tokenId);
                require(_nonce == _nonces[from._address][from._tokenId], "SpellsCoin: invalid nonce");
                ++_nonces[from._address][from._tokenId];
            } else {
                signer = _ownerOf(from._address);
                require(_nonce == _addressNonces[signer], "SpellsCoin: invalid nonce");
                ++_addressNonces[signer];
            }
            require(signer != address(0), "SpellsCoin: transfer from the zero address");
        } else {
            require(_nonce == _addressNonces[signer], "SpellsCoin: invalid nonce");
            ++_addressNonces[signer];
        }
        require(
            ECDSA.isValidAccessMessage(
                signer,
                keccak256(
                    abi.encodePacked(
                        msg.sender, // single-caller permission
                        from._address,
                        from._tokenId,
                        from._useZeroToken,
                        to._address,
                        to._tokenId,
                        to._useZeroToken,
                        amount,
                        _nonce
                    )
                ),
                _v,
                _r,
                _s
            ),
            "ERC20X: invalid signature"
        );
        
        _transfer(from, to, amount);
    }

    function _ownerOf(address _contract, uint256 tokenId)
        internal
        view
        returns (address)
    {
        return _IERC721(_contract).ownerOf(tokenId);
    }

    function _ownerOf(address _contract) internal view returns (address) {
        require(_contract != address(0), "SpellsCoin: zero address");
        (bool success, bytes memory returnData) = _contract.staticcall(
            abi.encodeWithSignature("owner()")
        );
        require(success, "SpellsCoin: could not assess owner");
        address owner = abi.decode(returnData, (address));
        return owner;
    }

    // Convenience method to allow withdrawal from contracts that do not support ERC-20.
    function withdrawFromContract(address _contract, uint256 amount)
        public
        nonReentrant
    {
        require(
            _contract != address(0),
            "SpellsCoin: transfer from the zero address"
        );
        require(msg.sender == _ownerOf(_contract), "SpellsCoin: invalid withdrawal");
        _transfer(_contract, msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}