/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

/// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.7;

/* |---------------------------------------------------------------------------|
   |                               Interfaces                                  |
   |---------------------------------------------------------------------------| */

/// @dev Defines UltraSwap router and its functions
interface UltraSwapRouter {
    function swap_eth_for_tokens(
        address token,
        address destination,
        uint256 min_out
    ) external payable returns (bool success);

    function swap_tokens_for_eth(
        address token,
        uint256 amount,
        address destination,
        uint256 min_out
    ) external returns (bool success);

    function swap_tokens_for_tokens(
        address token_1,
        address token_2,
        uint256 amount_1,
        address destination,
        uint256 min_out
    ) external returns (bool success);

    function add_liquidity_to_eth_pair(
        address tokek,
        uint256 qty,
        address destination
    ) external payable returns (bool success);

    function add_liquidity_to_token_pair(
        address token_1,
        address token_2,
        uint256 qty_1,
        uint256 qty_2,
        address destination
    ) external returns (bool success);

    function retireve_token_liquidity_from_eth_pair(
        address token,
        uint256 amount
    ) external returns (bool success);

    function retireve_token_liquidity_from_pair(
        address token_1,
        address token_2,
        uint256 amount
    ) external returns (bool success);

    function getPair(address token_1, address token_2)
        external
        returns (address pair_token);

    function get_liquidity_pair_info_eth(address tkn_1)
        external
        view
        returns (
            address _token_1,
            uint256 _qty_1,
            uint256 _qty_2,
            bool _active,
            uint256 token_per_eth
        );

    function get_liquidity_pair_info_tokens(address tkn_1, address tkn_2)
        external
        view
        returns (
            address _token_1,
            address _token_2,
            uint256 _qty_1,
            uint256 _qty_2,
            bool _active
        );

    function create_token(
        address deployer,
        address _router,
        uint256 _maxSupply,
        bytes32 _name,
        bytes32 _ticker,
        uint8 _decimals,
        uint8[4] memory _fees
    ) external payable returns (address new_token);
}

/* |---------------------------------------------------------------------------|
   |                       ERC20 Compliance with extension                     |
   |---------------------------------------------------------------------------| */

interface vERC20 {
    /****** Standard ERC20 interface functions ******/
    function totalSupply() external view returns (uint256 _totalSupply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (uint256 out, bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function decimals() external returns (uint256);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /****** Extended functions creating vERC20 from ERC20 ******/
    function getRouter() external view returns (address);

    function owner() external view returns (address);
}

/* |---------------------------------------------------------------------------|
   |                             ERC20 Extension                               |
   |---------------------------------------------------------------------------| */

/// @dev Helper contract to allow basic token properties and protections
contract virtualized {
    /// @dev Definitions

    uint256 public maxSupply;
    uint256 public circulatingSupply;
    uint8 public _decimals;

    bytes32 public name;
    bytes32 public ticker;

    uint8[4] fees;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    UltraSwapRouter public router_contract;

    address public router;

    /// @dev Protection features

    bool executing;

    modifier safe() {
        require(!executing);
        executing = true;
        _;
        executing = false;
    }

    address _owner_;
    mapping(address => bool) public is_auth;

    modifier authorized() {
        require(is_auth[msg.sender]);
        _;
    }

    modifier tokenOwner(address vtkn) {
        vERC20 TKN = vERC20(vtkn);
        require(TKN.owner() == msg.sender || TKN.getRouter() == msg.sender);
        _;
    }

    receive() external payable {}

    fallback() external {}
}

/* |---------------------------------------------------------------------------|
   |                       Virtual Liquidity Pair Contract                     |
   |---------------------------------------------------------------------------| */

contract UltraVirtualLiquidity {
    UltraSwapRouter router;
    address immutable token_1;
    address immutable token_2;
    bool immutable weth;

    constructor(
        address router_address,
        address tkn_1,
        address tkn_2,
        bool _weth
    ) {
        router = UltraSwapRouter(router_address);
        token_1 = tkn_1;
        token_2 = tkn_2;
        weth = _weth;
    }

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 zero
        )
    {
        uint256 _qty_1;
        uint256 _qty_2;
        address _token_1;
        address _token_2;
        bool _active;
        uint256 token_per_eth;

        if (weth) {
            (_token_1, _qty_1, _qty_2, _active, token_per_eth) = router
                .get_liquidity_pair_info_eth(token_1);
        } else {
            (_token_1, _token_2, _qty_1, _qty_2, _active) = router
                .get_liquidity_pair_info_tokens(token_1, token_2);
        }
        return (uint112(_qty_1), uint112(_qty_2), uint32(0));
    }
}

/* |---------------------------------------------------------------------------|
   |                            Deployable vERC20                              |
   |---------------------------------------------------------------------------| */

contract virtualERC20 is vERC20, virtualized {
    constructor(
        address deployer,
        address _router,
        uint256 _maxSupply,
        bytes32 _name,
        bytes32 _ticker,
        uint8 decimal_params,
        uint8[4] memory _fees
    ) {
        _owner_ = deployer;
        is_auth[deployer] = true;
        router = _router;
        is_auth[router] = true;
        router_contract = UltraSwapRouter(router);

        name = _name;
        ticker = _ticker;
        maxSupply = _maxSupply;
        circulatingSupply = _maxSupply;
        _decimals = decimal_params;
        fees = _fees;
    }

    /****** Specific functions ******/

    /// @dev Internal transfer function
    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) private returns (uint256 f_out) {}

    /****** ERC20 redirections to UltraSwap ******/

    function getRouter() public view override returns (address rtr) {
        return router;
    }

    function owner() public view override returns (address own) {
        return _owner_;
    }

    function totalSupply() public view override returns (uint256 _totalSupply) {
        return maxSupply;
    }

    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    /// @dev Entry point for UltraSwap transfer
    function transfer(address _to, uint256 _value)
        public
        override
        returns (uint256 out, bool success)
    {
        uint256 final_out = _transfer(msg.sender, _to, _value);
        return (final_out, true);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {}

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool success)
    {
        allowances[msg.sender][_spender] += _value;
        return true;
    }

    function decimals() public view override returns (uint256) {
        return _decimals;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowances[_owner][_spender];
    }
}

/* |---------------------------------------------------------------------------|
   |                             UltraLocker                                   |
   |---------------------------------------------------------------------------| */

contract UltraLocker is virtualized {
    mapping(address => uint256) public liquidity_owned_locker;

    function lock_liquidity(
        address staked,
        uint256 timed,
        uint256 perc
    ) public safe {}
}

/******************************* UltraSwap Main Logic *********************************/

/* |---------------------------------------------------------------------------|
   |                             Definitions                                   |
   |---------------------------------------------------------------------------| */

contract UltraSwap is virtualized, UltraSwapRouter {
    address public owner;
    address public dead = 0x0000000000000000000000000000000000000000;

    /**************** Liquidity Definition ************** */

    struct UltraLiquidity {
        mapping(address => uint256) liquidity_owned;
        address token_1;
        address token_2;
        address pair;
        uint256 qty_1;
        uint256 qty_2;
        bool exists;
        bool active;
    }

    mapping(address => mapping(uint256 => UltraLiquidity)) public liquidities;
    mapping(address => uint256) public token_liquidity_index;
    mapping(address => uint256[]) public token_liquidity;

    mapping(address => mapping(address => uint256))
        public token_liquidity_with_token;

    mapping(address => uint256) public token_liquidity_with_eth;

    /**************** Constructor ************** */

    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
    }

    /**************** vERC20 Creation ************** */

    function create_token(
        address deployer,
        address _router,
        uint256 _maxSupply,
        bytes32 _name,
        bytes32 _ticker,
        uint8 _decimals_,
        uint8[4] memory _fees
    ) public payable override safe returns (address new_token) {
        virtualERC20 _new_token = new virtualERC20(
            deployer,
            _router,
            _maxSupply,
            _name,
            _ticker,
            _decimals_,
            _fees
        );
        address token_address = address(_new_token);
        return token_address;
    }

    /* |---------------------------------------------------------------------------|
   |                             Public Functions                              |
   |---------------------------------------------------------------------------| */

    /// @dev Maths and management of eth to token swap
    function swap_eth_for_tokens(
        address token,
        address destination,
        uint256 min_out
    ) public payable override returns (bool success) {
        uint256 index_token_1 = token_liquidity_with_eth[token];
        require(
            liquidities[token][index_token_1].exists,
            "UltraSwap: INSUFFICIENT LIQUIDITY (AKA DOES NOT EXIST)"
        );
        vERC20 token_origin = vERC20(token);

        uint256 token_1_liquidity = liquidities[token][index_token_1].qty_1;
        uint256 token_2_liquidity = liquidities[token][index_token_1].qty_2;
        uint256 out = get_amount_out(
            msg.value,
            token_2_liquidity,
            token_1_liquidity
        );
        (uint256 final_out, bool _success) = token_origin.transfer(
            destination,
            out
        );
        require(_success, "Failed to transfer");
        require(final_out >= min_out, "UltraSwap: INSUFFICIENT OUTPUT");
        return true;
    }

    /// @dev Maths and management of token to eth swap
    function swap_tokens_for_eth(
        address token,
        uint256 amount,
        address destination,
        uint256 min_out
    ) public override tokenOwner(token) returns (bool success) {
        UltraLiquidity storage token_1_liquidity_local = liquidities[token][
            token_liquidity_with_eth[token]
        ];
        require(
            token_1_liquidity_local.exists,
            "UltraSwap: INSUFFICIENT LIQUIDITY (AKA DOES NOT EXIST)"
        );
        vERC20 token_origin = vERC20(token);

        uint256 out = get_amount_out(
            amount,
            token_1_liquidity_local.qty_1,
            token_1_liquidity_local.qty_2
        );
        (uint256 final_out, bool _success) = token_origin.transfer(
            destination,
            out
        );
        require(_success, "Failed to transfer");
        require(final_out >= min_out, "UltraSwap: INSUFFICIENT OUTPUT");
        uint256 new_liquidity_1 = token_1_liquidity_local.qty_1 + amount;
        uint256 new_liquidity_2 = token_1_liquidity_local.qty_2 - final_out;
        modify_eth_liquidity_after_swap(
            token,
            new_liquidity_1,
            new_liquidity_2
        );
        return true;
    }

    /// @dev Maths and management of token to token swap
    function swap_tokens_for_tokens(
        address token_1,
        address token_2,
        uint256 amount_1,
        address destination,
        uint256 min_out
    ) public override tokenOwner(token_1) returns (bool success) {
        UltraLiquidity storage token_1_liquidity_local = liquidities[token_1][
            token_liquidity_with_token[token_1][token_2]
        ];

        require(
            token_1_liquidity_local.exists,
            "UltraSwap: INSUFFICIENT LIQUIDITY (AKA DOES NOT EXIST)"
        );
        vERC20 token_origin = vERC20(token_1);

        uint256 out = get_amount_out(
            amount_1,
            token_1_liquidity_local.qty_1,
            token_1_liquidity_local.qty_2
        );

        (uint256 final_out, bool _success) = token_origin.transfer(
            destination,
            out
        );
        require(_success, "Failed to transfer");
        require(final_out >= min_out, "UltraSwap: INSUFFICIENT OUTPUT");
        uint256 new_liquidity_1 = token_1_liquidity_local.qty_1 + amount_1;
        uint256 new_liquidity_2 = token_1_liquidity_local.qty_2 - final_out;
        modify_token_liquidity_after_swap(
            token_1,
            token_2,
            new_liquidity_1,
            new_liquidity_2
        );
        return true;
    }

    /// @dev Returns the liquidity proportion between a token and eth liquidity
    function get_proportions_on_liquidity_eth(address token)
        public
        view
        returns (uint256 proportion)
    {
        uint256 index = token_liquidity_with_eth[token];
        require(liquidities[token][index].exists, "Liquidity does not exists");
        return ((liquidities[token][index].qty_1 * 100) /
            liquidities[token][index].qty_2);
    }

    /// @dev Returns the liquidity proportion between a token to token liquidity
    function get_proportions_on_liquidity_token(
        address token_1,
        address token_2
    ) public view returns (uint256 proportion) {
        uint256 index = token_liquidity_with_token[token_1][token_2];
        require(
            liquidities[token_1][index].exists,
            "Liquidity does not exists"
        );
        return ((liquidities[token_1][index].qty_1 * 100) /
            liquidities[token_1][index].qty_2);
    }

    /* |---------------------------------------------------------------------------|
   |                          Private Swap Functions                           |
   |---------------------------------------------------------------------------| */

    /// @dev Method reserved for swap functions to actually modify the liquidity 
    ///      based on eth based swap outcome
    function modify_eth_liquidity_after_swap(
        address token,
        uint256 new_liquidity_1,
        uint256 new_liquidity_2
    ) private returns (uint256 liq_1, uint256 liq_2) {
        uint256 index_token_1 = token_liquidity_with_eth[token];
        require(
            liquidities[token][index_token_1].exists,
            "UltraSwap: INSUFFICIENT LIQUIDITY (AKA DOES NOT EXIST)"
        );
        liquidities[token][index_token_1].qty_1 = new_liquidity_1;
        liquidities[token][index_token_1].qty_2 = new_liquidity_2;
        return (new_liquidity_1, new_liquidity_2);
    }

    /// @dev Method reserved for swap functions to actually modify the liquidity 
    ///      based on token based swap outcome
    function modify_token_liquidity_after_swap(
        address token_1,
        address token_2,
        uint256 new_liquidity_1,
        uint256 new_liquidity_2
    ) private returns (uint256 liq_1, uint256 liq_2) {
        uint256 index_token_1 = token_liquidity_with_token[token_1][token_2];
        require(
            liquidities[token_1][index_token_1].exists,
            "UltraSwap: INSUFFICIENT LIQUIDITY (AKA DOES NOT EXIST)"
        );
        liquidities[token_1][index_token_1].qty_1 = new_liquidity_1;
        liquidities[token_1][index_token_1].qty_2 = new_liquidity_2;
        return (new_liquidity_1, new_liquidity_2);
    }

    /// @dev Calculate the output amount given a swap
    // @param to_deposit Quantity of token_1 to deposit in pair
    // @param to_deposit_liq Liquidity of token_1
    // @param to_withdraw_liq Liquidity of token_2
    function get_amount_out(
        uint256 to_deposit,
        uint256 to_deposit_liq,
        uint256 to_withdraw_liq
    ) private pure returns (uint256 out_qty) {
        require(to_deposit > 0, "UltraSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(
            to_deposit_liq > 0 && to_withdraw_liq > 0,
            "UltraSwap: INSUFFICIENT_LIQUIDITY"
        );
        uint256 to_deposit_with_fee = to_deposit * (997);
        uint256 numerator = to_deposit_with_fee * (to_withdraw_liq);
        uint256 denominator = to_deposit_liq * (1000) + (to_deposit_with_fee);
        out_qty = numerator / denominator;
        return out_qty;
    }

    /* |---------------------------------------------------------------------------|
   |                                  Factory                                  |
   |---------------------------------------------------------------------------| */

    /**************** Creation Functions ************** */

    /*
        UltraSwap Factory creates the liquidity automatically as soon as
        a liquidity operation is done on a non existant pair. 
        Methods are thus private and called if neededb by UltraSwap itself.
    */

    /// @dev Create liquidity pool for TOKEN/ETH
    function create_liquidity_with_eth(address token)
        private
        returns (uint256)
    {
        require(
            token_liquidity_with_eth[token] != 0,
            "This liquidity already exists"
        );
        token_liquidity_index[token] += 1;
        uint256 local_index = token_liquidity_index[token];
        token_liquidity_with_eth[token] == local_index;
        liquidities[token][local_index].exists = true;

        // TODO create virtual pair

        return token_liquidity_with_eth[token];
    }

    /// @dev Create liquidity pool for TOKEN/TOKEN
    function create_liquidity_with_token(address token_1, address token_2)
        private
        returns (uint256)
    {
        require(
            token_liquidity_with_token[token_1][token_2] != 0,
            "This liquidity already exists"
        );
        token_liquidity_index[token_1] += 1;
        uint256 local_index = token_liquidity_index[token_1];
        token_liquidity_with_token[token_1][token_2] == local_index;
        liquidities[token_1][local_index].exists = true;

        // TODO create virtual pair

        return token_liquidity_with_token[token_1][token_2];
    }

    /**************** Add and Retrieve Functions ***************/

    /// @dev Adding ETH liquidity by checking proportions, transferring values and updating records included owned part of the pool
    function add_liquidity_to_eth_pair(
        address token,
        uint256 qty,
        address destination
    ) public payable override safe returns (bool success) {
        uint256 index = token_liquidity_with_eth[token];
        uint256 proportion;
        // Allows to add a new liquidity pool
        if (!liquidities[token][index].exists) {
            index = create_liquidity_with_eth(token);
            proportion = 0;
        } else {
            // Requires proportions to be respected
            proportion = get_proportions_on_liquidity_eth(token);
            require(
                proportion == ((qty * 100) / msg.value),
                "You need the right proportion"
            );
        }
        // Actual transfer and update part
        require(
            vERC20(token).allowance(address(this), msg.sender) >= qty,
            "Allowance token 1"
        );
        vERC20(token).transferFrom(msg.sender, address(this), qty);
        liquidities[token][index].qty_1 += qty;
        liquidities[token][index].qty_2 += msg.value;
        liquidities[token][index].liquidity_owned[destination] += qty;

        return true;
    }

    /// @dev Adding TOKEN liquidity by checking proportions, transferring values and updating records included owned part of the pool
    function add_liquidity_to_token_pair(
        address token_1,
        address token_2,
        uint256 qty_1,
        uint256 qty_2,
        address destination
    ) public override safe returns (bool success) {
        uint256 index = token_liquidity_with_token[token_1][token_2];
        uint256 proportion;
        // Allows to add a new liquidity pool
        if (liquidities[token_1][index].exists) {
            index = create_liquidity_with_token(token_1, token_2);
            proportion = 0;
        } else {
            // Requires proportions to be respected
            proportion = get_proportions_on_liquidity_token(token_1, token_2);
            require(
                proportion == ((qty_1 * 100) / qty_2),
                "You need the right proportion"
            );
        }
        // Actual transfer and update part
        require(
            vERC20(token_1).allowance(address(this), msg.sender) >= qty_1,
            "Allowance token 1"
        );
        require(
            vERC20(token_2).allowance(address(this), msg.sender) >= qty_2,
            "Allowance token 2"
        );
        vERC20(token_1).transferFrom(msg.sender, address(this), qty_1);
        vERC20(token_2).transferFrom(msg.sender, address(this), qty_2);
        liquidities[token_1][index].qty_1 += qty_1;
        liquidities[token_1][index].qty_2 += qty_2;
        liquidities[token_1][index].liquidity_owned[destination] += qty_1;
        return true;
    }

    /// @dev Withdraw liquidity, if owned, from a eth pair
    function retireve_token_liquidity_from_eth_pair(
        address token,
        uint256 amount
    ) public override safe returns (bool success) {
        uint256 index = token_liquidity_with_eth[token];
        require(liquidities[token][index].exists, "No liquidity found");
        uint256 percentage_requested = (amount * 100) /
            liquidities[token][index].qty_1;
        require(
            liquidities[token][index].liquidity_owned[msg.sender] >=
                percentage_requested,
            "Not enough owned"
        );
        liquidities[token][index].liquidity_owned[
            msg.sender
        ] -= percentage_requested;
        uint256 tokens_to_give = (liquidities[token][index].qty_1 *
            percentage_requested) / 100;
        uint256 eth_to_give = (liquidities[token][index].qty_2 *
            percentage_requested) / 100;
        require(
            vERC20(token).balanceOf(address(this)) >= tokens_to_give,
            "Insufficient balance here"
        );
        require(
            address(this).balance >= eth_to_give,
            "Insufficient balance in eth here"
        );
        (uint256 transferred, ) = vERC20(token).transfer(
            msg.sender,
            tokens_to_give
        );
        (bool sent, ) = msg.sender.call{value: eth_to_give}("");
        require(sent && (transferred > 0), "Not transferred");
        return true;
    }

    /// @dev Withdraw liquidity, if owned, from a token pair
    function retireve_token_liquidity_from_pair(
        address token_1,
        address token_2,
        uint256 amount
    ) public override safe returns (bool success) {
        uint256 index = token_liquidity_with_token[token_1][token_2];
        require(liquidities[token_1][index].exists, "No liquidity found");
        uint256 percentage_requested = (amount * 100) /
            liquidities[token_1][index].qty_1;
        require(
            liquidities[token_1][index].liquidity_owned[msg.sender] >=
                percentage_requested,
            "Not enough owned"
        );
        liquidities[token_1][index].liquidity_owned[
            msg.sender
        ] -= percentage_requested;
        uint256 tokens_1_to_give = (liquidities[token_1][index].qty_1 *
            percentage_requested) / 100;
        uint256 tokens_2_to_give = (liquidities[token_1][index].qty_2 *
            percentage_requested) / 100;
        require(
            vERC20(token_1).balanceOf(address(this)) >= tokens_1_to_give,
            "Insufficient balance here (1)"
        );
        require(
            vERC20(token_2).balanceOf(address(this)) >= tokens_2_to_give,
            "Insufficient balance here (2)"
        );
        (uint256 transferred_1, ) = vERC20(token_1).transfer(
            msg.sender,
            tokens_1_to_give
        );
        (uint256 transferred_2, ) = vERC20(token_2).transfer(
            msg.sender,
            tokens_2_to_give
        );
        require((transferred_2 > 0) && (transferred_1 > 0), "Not transferred");
        return true;
    }

    /**************** View Functions ***************/

    /// @dev Return the values of the liquidity betweeen two tokens
    function get_liquidity_pair_info_tokens(address token_1, address token_2)
        public
        view
        override
        returns (
            address _token_1,
            address _token_2,
            uint256 _qty_1,
            uint256 _qty_2,
            bool _active
        )
    {
        uint256 index = token_liquidity_with_token[token_1][token_2];
        require(liquidities[token_1][index].exists, "Liquidity not existant");
        return (
            liquidities[token_1][index].token_1,
            liquidities[token_1][index].token_2,
            liquidities[token_1][index].qty_1,
            liquidities[token_1][index].qty_2,
            liquidities[token_1][index].active
        );
    }

    /// @dev Return the values of the liquidity betweeen a token and eth
    function get_liquidity_pair_info_eth(address token)
        public
        view
        override
        returns (
            address _token_1,
            uint256 _qty_1,
            uint256 _qty_2,
            bool _active,
            uint256 token_per_eth
        )
    {
        uint256 index = token_liquidity_with_eth[token];
        require(liquidities[token][index].exists, "Liquidity not existant");
        uint256 tkn_eth = (liquidities[token][index].qty_1 /
            liquidities[token][index].qty_2);
        return (
            liquidities[token][index].token_1,
            liquidities[token][index].qty_1,
            liquidities[token][index].qty_2,
            liquidities[token][index].active,
            tkn_eth
        );
    }

    /// @dev Get liquidities

    function get_liquidity_pairs(address token)
        private
        view
        returns (uint256[] memory pairs)
    {
        return token_liquidity[token];
    }

    function get_pair_with_token(address token_1, address token_2)
        private
        view
        returns (uint256 pair)
    {
        return token_liquidity_with_token[token_1][token_2];
    }

    function get_pair_with_eth(address token)
        private
        view
        returns (uint256 pair)
    {
        return token_liquidity_with_eth[token];
    }

    function getPair(address tkn_1, address tkn_2)
        public
        view
        override
        returns (address virtual_pair)
    {
        uint256 index;
        if (tkn_2 == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            index = get_pair_with_eth(tkn_1);
        } else {
            index = get_pair_with_token(tkn_1, tkn_2);
        }
        return liquidities[tkn_1][index].pair;
    }
}