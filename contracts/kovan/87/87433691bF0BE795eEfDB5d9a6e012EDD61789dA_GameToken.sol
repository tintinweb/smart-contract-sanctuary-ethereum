// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;

contract GameToken {
    // --- Auth ---
    mapping(address => uint256) public checks;

    function rely(address admin) external auth {
        checks[admin] = 1;
    }

    function deny(address admin) external auth {
        checks[admin] = 0;
    }

    modifier auth() {
        require(checks[msg.sender] == 1, "gameToken/not-authorized");
        _;
    }

    // --- ERC20 Data ---
    string public constant name = "Game Token";
    string public constant symbol = "GameT";
    string public constant version = "1";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    event Approval(address indexed src, address indexed admin, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH =
        0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(uint256 _chainId) {
        checks[msg.sender] = 1;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
    }

    // --- Token ---

    function transfer(address dst, uint256 amt) external returns (bool) {
        return transferFrom(msg.sender, dst, amt);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) public returns (bool) {
        require(balanceOf[src] >= amt, "GameToken/insufficient-balance");
        if (
            src != msg.sender && allowance[src][msg.sender] != type(uint256).max
        ) {
            require(
                allowance[src][msg.sender] >= amt,
                "GameToken/insufficient-allowance"
            );
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], amt);
        }
        balanceOf[src] = sub(balanceOf[src], amt);
        balanceOf[dst] = add(balanceOf[dst], amt);
        emit Transfer(src, dst, amt);
        return true;
    }

    function mint(address usr, uint256 amt) external auth {
        balanceOf[usr] = add(balanceOf[usr], amt);
        totalSupply = add(totalSupply, amt);
        emit Transfer(address(0), usr, amt);
    }

    function burn(address usr, uint256 amt) external {
        require(balanceOf[usr] >= amt, "GameToken/insufficient-balance");
        if (
            usr != msg.sender && allowance[usr][msg.sender] != type(uint256).max
        ) {
            require(
                allowance[usr][msg.sender] >= amt,
                "GameToken/insufficient-allowance"
            );
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], amt);
        }
        balanceOf[usr] = sub(balanceOf[usr], amt);
        totalSupply = sub(totalSupply, amt);
        emit Transfer(usr, address(0), amt);
    }

    function approve(address usr, uint256 amt) external returns (bool) {
        allowance[msg.sender][usr] = amt;
        emit Approval(msg.sender, usr, amt);
        return true;
    }

    // --- Alias ---
    function push(address usr, uint256 amt) external {
        transferFrom(msg.sender, usr, amt);
    }

    function pull(address usr, uint256 amt) external {
        transferFrom(usr, msg.sender, amt);
    }

    function move(
        address src,
        address dst,
        uint256 amt
    ) external {
        transferFrom(src, dst, amt);
    }

    // --- Approve by signature ---
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        holder,
                        spender,
                        nonce,
                        expiry,
                        allowed
                    )
                )
            )
        );

        require(holder != address(0), "GameToken/invalid-address-0");
        require(
            holder == ecrecover(digest, v, r, s),
            "GameToken/invalid-permit"
        );
        require(
            expiry == 0 || block.timestamp <= expiry,
            "GameToken/permit-expired"
        );
        require(nonce == nonces[holder]++, "GameToken/invalid-nonce");
        uint256 amt = allowed ? type(uint256).max : 0;
        allowance[holder][spender] = amt;
        emit Approval(holder, spender, amt);
    }
}