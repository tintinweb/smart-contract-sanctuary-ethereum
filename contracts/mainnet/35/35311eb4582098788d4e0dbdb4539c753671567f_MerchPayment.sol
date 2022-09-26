/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// File: MerchPaymentProd.sol

pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

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

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

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

pragma solidity 0.8.15;

contract MerchPayment is Owned {
    ERC20 public POWToken;
    ERC20 public PUNKSToken;
    address public powDest; 
    address public punksDest;

    uint256 public id;

    //map address => id => sizeClaimed (0 if not claimed)
    mapping(address => mapping(uint256 => uint256)) public addrIDSize;
    //map id => numSizes
    mapping(uint256 => uint256) public sizesOf;    
    //map id => POW(True) PUNKS(False) => Cost
    mapping(uint256 => mapping(bool => uint256)) public costOf;
    //map id => size => total
    mapping(uint256 => mapping(uint256 => uint256)) public maxOfIDSize;
    //map id => size => claimed
    mapping(uint256 => mapping(uint256 => uint256)) public claimedOfIDSize;

    uint256 windowOpens;
    uint256 windowCloses;

    event Purchase(address claimer, uint256[] sizes);

    constructor(
        address _POWToken, 
        address _PUNKSToken, 
        address _powDest, 
        address _punksDest, 
        uint256 _windowOpens, 
        uint256 _windowCloses
    ) Owned(msg.sender) {
        POWToken = ERC20(_POWToken);
        PUNKSToken = ERC20(_PUNKSToken);

        powDest = _powDest;
        punksDest = _punksDest;

        windowOpens = _windowOpens;
        windowCloses = _windowCloses;
    }

    function editTokens(address _POWToken, address _PUNKSToken) public onlyOwner {
        POWToken = ERC20(_POWToken);
        PUNKSToken = ERC20(_PUNKSToken);
    }

    function editDest(address _powDest, address _punksDest) public onlyOwner {
        powDest = _powDest;
        punksDest = _punksDest;
    }

    function editWindows(uint256 _windowOpens, uint256 _windowCloses) public onlyOwner {
        windowOpens = _windowOpens;
        windowCloses = _windowCloses;
    }

    function addItem(
        uint256[] memory sizeQuantities, 
        uint256 powCost, 
        uint256 punksCost
    ) public onlyOwner {
        uint sizesLen = sizeQuantities.length;

        costOf[id][true] = powCost;
        costOf[id][false] = punksCost;
        sizesOf[id] = sizesLen;

        for(uint256 i = 0; i < sizesLen;) {
            maxOfIDSize[id][i] = sizeQuantities[i];
            unchecked {
                ++i;
            }
        }

        id++;
    }
    
    function updateItem(
        uint256 _id,
        uint256[] memory sizeQuantities, 
        uint256 powCost, 
        uint256 punksCost
    ) public onlyOwner {
        require(_id < id, "UpdateItem: Invalid ID!");
        uint sizesLen = sizeQuantities.length;

        costOf[_id][true] = powCost;
        costOf[_id][false] = punksCost;
        sizesOf[_id] = sizesLen;

        for(uint256 i = 0; i < sizesLen;) {
            maxOfIDSize[_id][i] = sizeQuantities[i];
            unchecked {
                ++i;
            }
        }
    }

    function purchase(uint256[] memory sizes, bool isPOW) public {
        require(
            block.timestamp >= windowOpens && block.timestamp <= windowCloses,
            "Purchase: Window is closed"
        );
        uint sizesLen = sizes.length;
        require(
            sizesLen == id,
            "Purchase: Invalid size list"
        );
        uint256 totalCost;
        for(uint256 i = 0; i < sizesLen;){
            if(sizes[i] != 0){
                require(
                    addrIDSize[msg.sender][i] == 0,
                     "Purchase: Already Claimed Item"
                );
                addrIDSize[msg.sender][i] = sizes[i];

                totalCost += costOf[i][isPOW];
                require(
                    sizes[i] - 1 < sizesOf[i],
                    "Purchase: Selected Size Doesn't Exist!"
                );
                require(
                    claimedOfIDSize[i][sizes[i]-1]++ < maxOfIDSize[i][sizes[i]-1],
                    "Purchase: Selected Size Sold Out!"
                );

            }
            unchecked {
                ++i;
            }
        }

        if(isPOW) {
            POWToken.transferFrom(msg.sender, powDest, totalCost);
        } else {
            PUNKSToken.transferFrom(msg.sender, punksDest, totalCost);
        }

        emit Purchase(msg.sender, sizes);
    }

    function getPrice(uint256[] memory sizes, bool isPOW) public view returns (uint256 totalCost) {
        uint sizesLen = sizes.length;
        require(
            sizesLen == id,
            "Purchase: Invalid size list"
        );
        for(uint256 i = 0; i < sizesLen;){
            if(sizes[i] != 0){
                totalCost += costOf[i][isPOW];
            }
            unchecked {
                ++i;
            }
        }
    }
}