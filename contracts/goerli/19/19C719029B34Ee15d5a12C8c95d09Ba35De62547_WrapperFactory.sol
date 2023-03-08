// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20 } from "solmate/tokens/ERC20.sol";

abstract contract BaseWrapper is ERC20 {
    uint256 public constant UNIT = 1 ether;

    ERC20 public WRAPPED;

    event Wrap(
        address indexed from, 
        address indexed to, 
        uint256 tokenAmount,
        uint256 wrapperAmount
    );
    event Unwrap(
        address indexed from, 
        address indexed to, 
        uint256 tokenAmount,
        uint256 wrapperAmount
    );

    constructor(
    	address _token,
    	string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
    	WRAPPED = ERC20(_token);
    }
        
    function getWrapAmountOut(uint256 _tokenAmount) public view virtual returns (uint256);
    function getUnwrapAmountOut(uint256 _wrapperAmount) public view virtual returns (uint256);

    function wrap(
    	uint256 _tokenAmount, 
    	address _receiver
    ) external returns (uint256 wrapperAmount) {
        if (_tokenAmount == 0) revert PositiveAmountOnly();

    	wrapperAmount = getWrapAmountOut(_tokenAmount);
        
        _mint(_receiver, wrapperAmount);
        WRAPPED.transferFrom(msg.sender, address(this), _tokenAmount);

        emit Wrap(
            msg.sender, 
            _receiver,
            _tokenAmount,
            wrapperAmount
        );
    }

    function unwrap(
    	uint256 _wrapperAmount, 
    	address _receiver
    ) external returns (uint256 tokenAmount) {
        if (_wrapperAmount == 0) revert PositiveAmountOnly();

        tokenAmount = getUnwrapAmountOut(_wrapperAmount);

        _burn(msg.sender, _wrapperAmount);
    	WRAPPED.transfer(_receiver, tokenAmount);

        emit Unwrap(
            msg.sender, 
            _receiver,
            tokenAmount,
            _wrapperAmount
        );
    }

    error PositiveAmountOnly();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "./wrappers/FixedRatio.sol";
import "./wrappers/SharesBased.sol";

contract WrapperFactory {
    uint256 public nextId;
    mapping(uint256 => address) public wrapperById;

    event NewWrapper(
        address indexed wrapper, 
        address indexed token, 
        uint256 indexed wrapperType,
        address creator,
        uint256 id
    );

    constructor() {
    }
    
    
    //for 1:1 wrap:unwrap ratio must be 10**18
    function deployFixedRatio(
        address _token,
        uint256 _ratio,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external returns (FixedRatio wrapper) {
        if (_ratio == 0) revert RatioMustBePositive();

        wrapper = new FixedRatio(
            _token,
            _ratio,
            _name,
            _symbol,
            _decimals
        );

        wrapperById[nextId] = address(wrapper);

        emit NewWrapper(
            address(wrapper),
            _token,
            wrapper.WRAPPER_TYPE(),
            msg.sender,
            nextId
        );

        nextId += 1;
    }

    function deploySharesBased(
        address _token,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external returns (SharesBased wrapper) {
        wrapper = new SharesBased(
            _token,
            _name,
            _symbol,
            _decimals
        );

        wrapperById[nextId] = address(wrapper);

        emit NewWrapper(
            address(wrapper),
            _token,
            wrapper.WRAPPER_TYPE(),
            msg.sender,
            nextId
        );

        nextId += 1;
    }

    error RatioMustBePositive();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "../BaseWrapper.sol";

/*
https://etherscan.io/address/0xd0660cd418a64a1d44e9214ad8e459324d8157f1#code

1 YFI = 1,000,000 WOOFY

YFI     is 18 decimals
WOOFY   is 12 decimals

wrapperAmount = tokenAmount * ratio / UNIT
1000000*10**12 = 10**18 * x / 10**18
1000000*10**12 = x


example:
https://etherscan.io/tx/0x8af641514fe515690caf5d1ac913b1bf968dfb8a840ac9361a84fb4c5dfa8ecc

wrap(29885875670327548 YFI)

wrapperAmount = 29885875670327548 * 1000000*10**12 / 10**18
wrapperAmount = 29885875670327548 WOOFY
wrapperAmount = 29885.875670327548 * 10**12 WOOFY
*/

contract FixedRatio is BaseWrapper {
    string public constant WRAPPER_DESCRIPTION = "Fixed Ratio Wrapper";
    uint256 public constant WRAPPER_TYPE = 0;

    uint256 public ratio;

    constructor(
        address _token,
        uint256 _ratio,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) BaseWrapper(_token, _name, _symbol, _decimals) {
        ratio = _ratio;
    }

    function getWrapAmountOut(uint256 _tokenAmount) public view override returns (uint256) {
        return _tokenAmount * ratio / UNIT;
    }

    function getUnwrapAmountOut(uint256 _wrapperAmount) public view override returns (uint256) {
        return _wrapperAmount / ratio * UNIT;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "../BaseWrapper.sol";

/*
wstETH - like wrapper
*/

contract SharesBased is BaseWrapper {
    string public constant WRAPPER_DESCRIPTION = "Shares Based Wrapper";
    uint256 public constant WRAPPER_TYPE = 1;

    constructor(
        address _token,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) BaseWrapper(_token, _name, _symbol, _decimals) {
    }

    function getWrapAmountOut(uint256 _tokenAmount) public view override returns (uint256) {
        uint256 totalTokens = WRAPPED.balanceOf(address(this));
        if (totalTokens == 0) {
            //Handle first wrap()
            return _tokenAmount;
        }
        return _tokenAmount * totalSupply / totalTokens;
    }

    function getUnwrapAmountOut(uint256 _wrapperAmount) public view override returns (uint256) {
        if (totalSupply == 0) {
            return 0;
        }
        uint256 totalTokens = WRAPPED.balanceOf(address(this));
        return _wrapperAmount * totalTokens / totalSupply;
    }
}