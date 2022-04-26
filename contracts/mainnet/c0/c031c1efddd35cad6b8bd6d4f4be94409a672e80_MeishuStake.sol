/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}
interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
      address tokenA,
      address tokenB,
      uint amountADesired,
      uint amountBDesired,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface ERC20 {
    function decimals() external view returns(uint);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ERC20RewardToken is ERC20 {
    function mint_rewards(uint256 qty, address receiver) external;

    function burn_tokens(uint256 qty, address burned) external;
}

contract protected {
    mapping(address => bool) is_auth;

    function is_it_auth(address addy) public view returns (bool) {
        return is_auth[addy];
    }

    function set_is_auth(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }

    modifier onlyAuth() {
        require(is_auth[msg.sender] || msg.sender == owner, "not owner");
        _;
    }

    address owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
}


/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract smart {
    address router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    IUniswapRouter02 router = IUniswapRouter02(router_address);

    uint kaiBalance;
    uint meishuBalance;
    uint kaiTax = 1; // 1%
    uint meishuFee = 100000000000000000; // 0,1 ETH

    function create_weth_pair(address token) private returns (address, IUniswapV2Pair) {
       address pair_address = IUniswapFactory(router.factory()).createPair(token, router.WETH());
       return (pair_address, IUniswapV2Pair(pair_address));
    }

    function get_weth_reserve(address pair_address) private  view returns(uint, uint) {
        IUniswapV2Pair pair = IUniswapV2Pair(pair_address);
        uint112 token_reserve;
        uint112 native_reserve;
        uint32 last_timestamp;
        (token_reserve, native_reserve, last_timestamp) = pair.getReserves();
        return (token_reserve, native_reserve);
    }

    function get_weth_price_impact(address token, uint amount, bool sell) private view returns(uint) {
        address pair_address = IUniswapFactory(router.factory()).getPair(token, router.WETH());
        (uint res_token, uint res_weth) = get_weth_reserve(pair_address);
        uint impact;
        if(sell) {
            impact = (amount * 100) / res_token;
        } else {
            impact = (amount * 100) / res_weth;
        }
        return impact;
    }
}

contract  calendar {
    function get_year_to_uint() public pure returns(uint) {
        return(365 days);
    }
    function get_month_to_uint() public pure returns(uint) {
        return(30 days);
    } 
    function get_week_to_uint() public pure returns(uint) {
        return(7 days);
    }
    function get_day_to_uint() public pure returns(uint) {
        return(1 days);
    }
    function get_x_days_to_uint(uint16 _days) public pure returns(uint) {
        return((1 days*_days));
    }
}

/********************  MEISHU NFT STAKING  *********************/

contract MeishuStake is protected, smart,calendar {
    receive() payable external {}
    fallback() external {}

    mapping(address => bool) public nft_addresses;
    bool public nft_lock;

    address public default_earning;
    mapping(address => address) public custom_earning;

    mapping(address => mapping(uint => uint)) public nft_rewards;

    mapping(address => uint) public custom_floor;

    uint public _common_reward;

    ///@dev Modifiers rates
    uint burn_rate;
    uint penalty_rate;


    ///@dev Updated each time a floor is added or removed
    uint total_floors;

    struct SINGLE_STAKE {
        address nft;
        uint token_id;
        ERC721 nft_token;
        address earned;
        ERC20 earned_token;
        uint8 qty;
        uint floor;
        uint start_time;
        uint timelocked;
        uint rewards;
        bool active;
        bool exists;
        bool floor_based;
    }

    mapping(uint => bool) public times;

    struct STAKEHOLDER {
        mapping(uint => SINGLE_STAKE) stakes;
        uint total_withdraw;
        uint total_staked_value;
        uint last_stake;
        uint[] closed_pools;
        bool blacklisted;
    }

    mapping (address => STAKEHOLDER) stakeholder;

    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
        times[30 days] = true;
        times[60 days] = true;
        times[90 days] = true;
        /*
        30 days = 2592000
        60 days = 5184000
        90 days = 7776000
        */
    }

    ///@dev Stake a specific NFT
    function stake_nft(address _nft, uint id, uint timelock) payable public safe {
        if(nft_lock) {
            require(nft_addresses[_nft], "This staking support other nfts");
        }
        require(times[timelock], "Timelock wrong");
        require(msg.value==meishuFee, "Underpaid or overpaid"); // 0.1 ETH pays for fees and gas
        uint kaiPart = (meishuFee * kaiTax)/100;
        kaiBalance += kaiPart; // 1% to Kaiba 
        meishuBalance = meishuFee - kaiPart;

        require(ERC721(_nft).isApprovedForAll(msg.sender, address(this)), "Pleasea approve transfer status");
        stakeholder[msg.sender].last_stake = stakeholder[msg.sender].last_stake + 1;
        uint last_stake = stakeholder[msg.sender].last_stake;
        // Configure the stake
        stakeholder[msg.sender].stakes[last_stake].nft  = _nft;
        stakeholder[msg.sender].stakes[last_stake].nft_token  = ERC721(_nft);
        // Check if there is a particular token to earn
        if(custom_earning[_nft]==DEAD) {
            stakeholder[msg.sender].stakes[last_stake].earned = default_earning;
            stakeholder[msg.sender].stakes[last_stake].earned_token = ERC20(default_earning);
        } else {
            stakeholder[msg.sender].stakes[last_stake].earned = custom_earning[_nft];
            stakeholder[msg.sender].stakes[last_stake].earned_token = ERC20(custom_earning[_nft]);     
        }
        // Check if there is a particular reward rate
        stakeholder[msg.sender].stakes[last_stake].rewards = _common_reward;
        
        // Transfer and last settings
        ERC721(_nft).transferFrom(msg.sender, address(this), id);
        stakeholder[msg.sender].stakes[last_stake].token_id = id;
        stakeholder[msg.sender].stakes[last_stake].qty = 1;
        stakeholder[msg.sender].stakes[last_stake].floor = custom_floor[_nft];
        stakeholder[msg.sender].stakes[last_stake].start_time = block.timestamp;
        stakeholder[msg.sender].stakes[last_stake].active = true;
        stakeholder[msg.sender].stakes[last_stake].exists = true;
        total_floors += custom_floor[_nft];
    }

    ///@dev Approve the transfer of a token (must be called before staking)
    function approve_nft_on_contract(address _nft) public {
        ERC721(_nft).setApprovalForAll(address(this), true);
    }

    ///@dev Set the burn rate
    function set_burn_rate(uint rate) public onlyAuth {
        burn_rate = rate;
    }

    ///@dev Set the penalty rate
    function set_penalty_rate(uint rate) public onlyAuth {
        penalty_rate = rate;
    }

    ///@dev Set the default earning token
    function set_base_earning(address _earning) public onlyAuth {
        default_earning = _earning;
    }

    ///@dev Set custom reward for an nft (yearly based)
    function set_nft_reward(address _nft, uint _time, uint _reward) public onlyAuth {
        nft_rewards[_nft][_time] = _reward;
    }

    function set_common_reward(uint _reward) public onlyAuth {
        _common_reward = _reward;
    }

    ///@dev Set custom earning token for an nft
    function set_custom_earning(address _nft, address _earning) public onlyAuth {
        custom_earning[_nft] = _earning;
    }

    ///@dev set floor for a specific nft
    function set_floor_on(address _nft, uint _floor) public onlyAuth {
        custom_floor[_nft] = _floor;
    }

    ///@dev set floor for a specific pool updating total_floors
    function set_pool_floor(address _stakeholder, uint _id, uint _floor) public onlyAuth {
        require(stakeholder[_stakeholder].stakes[_id].exists, "Pool is unconfigured");
        uint old_floor = stakeholder[_stakeholder].stakes[_id].floor;
        total_floors -= old_floor;
        stakeholder[_stakeholder].stakes[_id].floor = _floor;
        total_floors += _floor;
    }

    ///@dev invalidate a pool
    function invalidate_pool(address _stakeholder, uint _id) public onlyAuth {
        require(stakeholder[_stakeholder].stakes[_id].exists, "Pool is unconfigured");
        stakeholder[_stakeholder].stakes[_id].exists = false;
        uint old_floor = stakeholder[_stakeholder].stakes[_id].floor;
        total_floors -= old_floor;
    }

    ///@dev Enable or disable a time
    function set_time_status(uint timed, bool booly) public onlyAuth {
        times[timed] = booly;
    }

    ///@dev get balance
    function set_staking_fee(uint wei_fee) public onlyAuth {
        meishuFee = wei_fee;
    }

    ///@dev get balance
    function set_kaiba_share(uint perc_share) public onlyAuth {
        kaiTax = perc_share;
    }

    ///@dev get balance
    function retrieve_meishu_balance() public onlyAuth {
        if(!(address(this).balance >= meishuBalance)) {
            meishuBalance = (address(this).balance*kaiTax)/100;
            kaiBalance = address(this).balance - meishuBalance;
        }
        (bool sent,) = msg.sender.call{value: meishuBalance}("");
        require(sent, "Can't withdraw");
    }

    ///@dev get kaiba share    
    function retrieve_kaiba_balance() public onlyAuth {
        if(!(address(this).balance >= kaiBalance)) {
            meishuBalance = (address(this).balance*kaiTax)/100;
            kaiBalance = address(this).balance - meishuBalance;
        }
        (bool sent,) = msg.sender.call{value: kaiBalance}("");
        require(sent, "Can't withdraw");
    }

    ///@dev solve stuck problems
    function unstuck() public onlyAuth {
        meishuBalance = 0;
        kaiBalance = 0;
        (bool sent,) = msg.sender.call{value: address(this).balance-1}("");
        require(sent, "Can't withdraw");
    }
    /************************* Views *************************/

    ///@dev get a single pool
    function get_stakeholder_single_pool(address _stakeholder, uint _id) public view returns(
        address _nft,
        uint _nft_id,
        address _earned,
        uint _start_time,
        uint _locktime,
        uint _reward)
        {
        require(stakeholder[_stakeholder].stakes[_id].exists, "Pool is unconfigured");
        return(
            stakeholder[_stakeholder].stakes[_id].nft,
            stakeholder[_stakeholder].stakes[_id].token_id,
            stakeholder[_stakeholder].stakes[_id].earned,
            stakeholder[_stakeholder].stakes[_id].start_time,
            stakeholder[_stakeholder].stakes[_id].timelocked,
            stakeholder[_stakeholder].stakes[_id].rewards
        );
    }

    ///@dev get all the pools

    function get_all_pools(address stkholder) public view returns (uint all_pools, uint[] memory closed_pools) {
        return( stakeholder[stkholder].last_stake,
                stakeholder[stkholder].closed_pools);
    }

    ///@dev calculate reward based on emission

    function get_rewards_on(address _stakeholder, uint _id) public view returns(uint _reward) {
        require(stakeholder[_stakeholder].stakes[_id].exists, "Pool is unconfigured");
        require(stakeholder[_stakeholder].stakes[_id].active, "Pool is inactive");
        uint reward = _common_reward;
        uint start_time = stakeholder[_stakeholder].stakes[_id].start_time;
        uint this_reward = _get_rewards(reward, start_time);
        return this_reward;
    }

    function _get_rewards(uint reward, uint start_time) private view returns (uint uf_reward){
        uint delta_time = block.timestamp - start_time;
        uint year_perc = (delta_time * 1000000) / get_year_to_uint();
        uint actual_reward = ((reward * year_perc) / 100)/10000;
        return actual_reward;
    }

    ///@dev Calculate annual return
    function get_annual_return(address _stakeholder, uint _id) public view returns (uint _reward_value){
        address reward = stakeholder[_stakeholder].stakes[_id].earned;
        uint amount = get_rewards_on(_stakeholder, _id);
        uint reward_value = getTokenPrice(reward, amount);
        return reward_value;
    }

    ///@dev Calculate APY
    /* function get_apy(address _stakeholder, uint _id) public view returns (uint _apy){
        address _nft = stakeholder[_stakeholder].stakes[_id].nft;
        address earned;
        uint reward;
        if(custom_earning[_nft]==DEAD) {
            earned = default_earning;
        } else {
            earned = custom_earning[_nft]; 
        }
        // Check if there is a particular reward rate
        if(custom_reward[_nft]==0) {
            reward = default_reward;
        } else {
            reward = custom_reward[_nft];     
        }
        uint reward_value = getTokenPrice(earned, reward);
        uint apy = (reward_value*100)/reward;
        return apy;
    } */

    ///@dev Tokens (ERC20) price
    function getTokenPrice(address tkn, uint amount) public view returns(uint)
        {
            IUniswapFactory factory = IUniswapFactory(router.factory());
            address pairAddress = factory.getPair(tkn, router.WETH());
            IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
            ERC20 token1 = ERC20(pair.token1());
        
        
            (uint Res0, uint Res1,) = pair.getReserves();

            // decimals
            uint res0 = Res0*(10**token1.decimals());
            return((amount*res0)/Res1); // return amount of token0 needed to buy token1
    }

    ///@dev Payout earnings
    function withdraw_earnings(address _stakeholder, uint _id) public safe {
        require(msg.sender == _stakeholder, "Don't steal");
        require(block.timestamp >= (stakeholder[_stakeholder].stakes[_id].start_time+1 hours),"Wait.");
        bool penalty;
        if(block.timestamp < (stakeholder[_stakeholder].stakes[_id].start_time + 15 days)) {
            penalty = true;
        }
        address earning = stakeholder[_stakeholder].stakes[_id].earned;
        uint reward_amount_raw = get_rewards_on(_stakeholder, _id);
        uint burn_amount = (reward_amount_raw * burn_rate)/100;
        uint penalty_amount;
        if(penalty) {
            penalty_amount = (reward_amount_raw * penalty_rate)/100;
        }
        uint reward_amount = reward_amount_raw - burn_amount - penalty_amount;
        require(ERC20(earning).balanceOf(address(this)) >= reward_amount, "Not enough tokens");
        ERC20(earning).transfer(_stakeholder, reward_amount);
        ERC20(earning).transfer(DEAD, burn_amount);
        stakeholder[_stakeholder].total_withdraw += reward_amount;
        stakeholder[_stakeholder].stakes[_id].start_time = block.timestamp;
        private_recover_pool(_stakeholder, _id, msg.sender, stakeholder[_stakeholder].stakes[_id].token_id);

    } 

    /************************* Control Panel *************************/

    function ctrl_disband() public onlyAuth {
        selfdestruct(payable(owner));
    }

    function ctrl_allow_nft(address nftaddy, bool booly) public onlyAuth {
        nft_addresses[nftaddy] = booly;
    }

    function ctrl_universal_staking(bool booly) public onlyAuth {
        nft_lock = booly;
    }

    /// @dev Forcibly unset a pool
    function ctrl_unstuck_token(address _stakeholder, uint _id, address caller, uint _token_id) public onlyAuth {
        private_recover_pool(_stakeholder, _id, caller, _token_id);
    }

    /// @dev Forcibly set a pool
    function ctrl_remake_pool(address _nft, uint id, address staker) public onlyAuth {
        require(ERC721(_nft).isApprovedForAll(msg.sender, address(this)), "Pleasea approve transfer status");
        stakeholder[staker].last_stake = stakeholder[staker].last_stake + 1;
        uint last_stake = stakeholder[staker].last_stake;
        // Configure the stake
        stakeholder[staker].stakes[last_stake].nft  = _nft;
        stakeholder[staker].stakes[last_stake].nft_token  = ERC721(_nft);
        // Check if there is a particular token to earn
        if(custom_earning[_nft]==DEAD) {
            stakeholder[staker].stakes[last_stake].earned = default_earning;
            stakeholder[staker].stakes[last_stake].earned_token = ERC20(default_earning);
        } else {
            stakeholder[staker].stakes[last_stake].earned = custom_earning[_nft];
            stakeholder[staker].stakes[last_stake].earned_token = ERC20(custom_earning[_nft]);     
        }
        // Check if there is a particular reward rate
        stakeholder[staker].stakes[last_stake].rewards = _common_reward;
        
        // Transfer and last settings
        ERC721(_nft).transferFrom(msg.sender, address(this), id);
        stakeholder[staker].stakes[last_stake].token_id = id;
        stakeholder[staker].stakes[last_stake].qty = 1;
        stakeholder[staker].stakes[last_stake].floor = custom_floor[_nft];
        stakeholder[staker].stakes[last_stake].start_time = block.timestamp;
        stakeholder[staker].stakes[last_stake].active = true;
        stakeholder[staker].stakes[last_stake].exists = true;
        total_floors += custom_floor[_nft];
    }
    /************************* Private Helpers *************************/

    function private_recover_pool(address _stakeholder, uint _id, address caller, uint _token_id) private {
        // Update total floor
        uint old_floor = stakeholder[_stakeholder].stakes[_id].floor;
        total_floors -= old_floor;
        // Takes back nft
        if(!is_auth[caller]) {
            require(ERC721(stakeholder[_stakeholder].stakes[_id].nft).ownerOf(_token_id) == address(this), "Nope");
        }
        ERC721(stakeholder[_stakeholder].stakes[_id].nft).transferFrom(address(this), caller, _token_id);
        // Unsetting all
        stakeholder[_stakeholder].closed_pools.push(_id);
        stakeholder[_stakeholder].stakes[_id].nft = DEAD;
        stakeholder[_stakeholder].stakes[_id].earned  = DEAD;
        stakeholder[_stakeholder].stakes[_id].qty  = 0;
        stakeholder[_stakeholder].stakes[_id].floor = 0;
        stakeholder[_stakeholder].stakes[_id].start_time = 0;
        stakeholder[_stakeholder].stakes[_id].rewards = 0;
        stakeholder[_stakeholder].stakes[_id].active = false;
        stakeholder[_stakeholder].stakes[_id].exists = false;
        stakeholder[_stakeholder].stakes[_id].floor_based = false;
    }
}