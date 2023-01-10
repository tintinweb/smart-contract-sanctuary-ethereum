/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

/// d2O.sol -- d2O token

pragma solidity ^0.8.7;

contract d2O {
    address public ArchAdmin;
    mapping (address => uint256) public admins;

    // --- ERC20 Data ---
    string  public constant name     = "Deuterium";
    string  public constant symbol   = "d2O";
    string  public constant version  = "1";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;
    uint256 public live;
    uint256 public transferBlockWait;           //Amount of blocks to wait before user can transfer d2O after minting cross-chain
    uint256 public lockupTriggerAmt;            //d2O amount where lockup will kick in after cross-chain transfer

    mapping (address => uint256)                        public balanceOf;
    mapping (address => mapping (address => uint256))   public allowance;
    mapping (address => uint256)                        public nonces;
    mapping (address => uint256)                        public transferBlockRelease;    //Block number after which user is able to transfer d2O

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferBlockWait(uint256 blockWait);
    event TransferBlockUpdate(address indexed user, uint256 blockNumer);
    event LockupTriggerAmount(uint256 amount);
    event Cage(uint256 status);
    

    // --- EIP712 niceties ---
    uint256 public immutable deploymentChainId;
    bytes32 private immutable _DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    modifier auth {
        require(admins[msg.sender] == 1, "d2O/not-authorized");
        _;
    }

    modifier alive {
        require(live == 1, "d2O/not-live");
        _;
    }

    constructor() {
        live = 1;
        admins[msg.sender] = 1;
        ArchAdmin = msg.sender;
        emit Rely(msg.sender);

        deploymentChainId = block.chainid;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(block.chainid);
    }

    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return block.chainid == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    // --- Administration ---

    function setArchAdmin(address newArch) external auth {
        require(ArchAdmin == msg.sender && newArch != address(0), "d2O/Must be ArchAdmin");
        ArchAdmin = newArch;
        admins[ArchAdmin] = 1;
    }

    function rely(address usr) external auth {
        admins[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        require(usr != ArchAdmin, "d2O/ArchAdmin cannot lose admin - update ArchAdmin to another address");
        admins[usr] = 0;
        emit Deny(usr);
    }

    function cage(uint256 _live) external auth {
        live = _live;
        emit Cage(_live);
    }

    function setTransferBlockWait(uint256 num) external auth {
        transferBlockWait = num;
        emit TransferBlockWait(transferBlockWait);
    }

    function setTransferBlockRelease(address user, uint256 blockNumber) external auth {
        transferBlockRelease[user] = blockNumber;
        emit TransferBlockUpdate(user, blockNumber);
    }

    function setLockupTriggerAmount(uint256 amount) external auth {
        lockupTriggerAmt = amount;
        emit LockupTriggerAmount(amount);
    }

    // --- ERC20 Mutations ---
    function transfer(address to, uint256 value) external alive returns (bool) {
        require(to != address(0) && to != address(this), "d2O/invalid-address");
        require(block.number > transferBlockRelease[msg.sender], "d2O/transfer too soon after cross-chain mint");
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "d2O/insufficient-balance");

        unchecked {
            balanceOf[msg.sender] = balance - value;
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external alive returns (bool) {
        require(to != address(0) && to != address(this), "d2O/invalid-address");
        require(block.number > transferBlockRelease[from], "d2O/transfer too soon after cross-chain mint");
        uint256 balance = balanceOf[from];
        require(balance >= value, "d2O/insufficient-balance");

        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "d2O/insufficient-allowance");

                unchecked {
                    allowance[from][msg.sender] = allowed - value;
                }
            }
        }

        unchecked {
            balanceOf[from] = balance - value;
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        uint256 newValue = allowance[msg.sender][spender] + addedValue;
        allowance[msg.sender][spender] = newValue;

        emit Approval(msg.sender, spender, newValue);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        return _decreaseAllowance(msg.sender, spender, subtractedValue);
    }
    
    function decreaseAllowanceAdmin(address owner, address spender, uint256 subtractedValue) external auth returns (bool) {
        return _decreaseAllowance(owner, spender, subtractedValue);
    } 

    function _decreaseAllowance(address owner, address spender, uint256 subtractedValue) internal returns (bool) {
        uint256 allowed = allowance[owner][spender];
        require(allowed >= subtractedValue, "d2O/insufficient-allowance");
        unchecked{
            allowed = allowed - subtractedValue;
        }
        allowance[owner][spender] = allowed;

        emit Approval(owner, spender, allowed);

        return true;
    }

    // --- Mint/Burn ---
    function mint(address to, uint256 value) external auth {
        _mint(to, value);
    }

    function mintAndDelay(address to, uint256 value) external auth {
        if(value > lockupTriggerAmt){
            transferBlockRelease[to] = block.number + transferBlockWait;
        }
        _mint(to, value);
    }

    function _mint(address to, uint256 value) internal alive {
        require(to != address(0) && to != address(this), "d2O/invalid-address");
        unchecked {
            balanceOf[to] = balanceOf[to] + value; // note: we don't need an overflow check here b/c balanceOf[to] <= totalSupply and there is an overflow check below
        }
        totalSupply = totalSupply + value;

        emit Transfer(address(0), to, value);
    }

    function burn(address from, uint256 value) external alive {
        uint256 balance = balanceOf[from];
        require(balance >= value, "d2O/insufficient-balance");
        require(block.number > transferBlockRelease[from] || admins[msg.sender] == 1, "d2O/burn too soon after cross-chain mint");

        if (from != msg.sender && admins[msg.sender] != 1) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "d2O/insufficient-allowance");

                unchecked {
                    allowance[from][msg.sender] = allowed - value;
                }
            }
        }

        unchecked {
            balanceOf[from] = balance - value; // note: we don't need overflow checks b/c require(balance >= value) and balance <= totalSupply
            totalSupply     = totalSupply - value;
        }

        emit Transfer(from, address(0), value);
    }

    // --- Approve by signature ---
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "d2O/permit-expired");

        uint256 nonce;
        unchecked { nonce = nonces[owner]++; }

        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                block.chainid == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid),
                keccak256(abi.encode(
                    PERMIT_TYPEHASH,
                    owner,
                    spender,
                    value,
                    nonce,
                    deadline
                ))
            ));

        require(owner != address(0) && owner == ecrecover(digest, v, r, s), "d2O/invalid-permit");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}