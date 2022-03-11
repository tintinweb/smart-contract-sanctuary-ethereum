// SPDX-License-Identifier: MIT
//   
//                    ▄█           
//                  ▄███           
//               ,▓█████           
//        ╓▓█████████████████████▀`
//      ╓████████████████████▀╓╛   
//     ▐█████████████████▀╙ ,╛     
//     ███████████████▀─  ╓╜       
//     ███████████▀╙    ╓╙         
//     ╟█████████      ╟██▄,       
//      ╙████████      ╟█████▄     
//        ╙▀█████      ╟███████    
//            └╟▀    ,▄█████████   
//           #╙   ▄▓████████████   
//         #└ ,▄███████████████▌   
//       é─▄▓█████████████████▀    
//    ,Q▄███████████████████▀─     
//   "▀▀▀▀▀▀▀▀▀▀██████▀▀▀╙─        
//              ████▀              
//              ██▀                
//              └      
//   
pragma solidity ^0.7.3;

import "../interfaces/IERC20.sol";
import "../interfaces/IChainlinkOracle.sol";

contract ChainCardView {
    uint256 public constant token_precision = 1e18;
    uint256 public constant chainlink_precision = 1e8;
    
    address public seigniorage_token;
    address public stable_token;
    address public stable_pair;
    address public stable_oracle;
    address public native_oracle;
    bool public own_wallet_balance_gaslimit_correction;

    constructor(address _seigniorage_token, address _stable_token, address _stable_pair, address _stable_oracle, address _native_oracle, bool _own_wallet_balance_gaslimit_correction) {
        seigniorage_token = _seigniorage_token;
        stable_token = _stable_token;
        stable_pair = _stable_pair;
        stable_oracle = _stable_oracle;
        native_oracle = _native_oracle;
        own_wallet_balance_gaslimit_correction = _own_wallet_balance_gaslimit_correction;
    }

    function populateCard(address user_wallet) external view 
       returns (uint256 user_seigniorage_balance,
                uint256 user_seigniorage_value,
                uint256 user_native_amount,
                uint256 user_native_value,
                uint256 user_stable_amount,
                uint256 user_stable_value,
                uint256 amm_seigniorage_stable_ratio,
                uint256 amm_seigniorage_stable_price,
                uint256 native_price) {
      uint256 gaslimit = gasleft();
      uint256 stable_price = IChainlinkOracle(stable_oracle).latestAnswer();
      native_price = IChainlinkOracle(native_oracle).latestAnswer();
      user_seigniorage_balance = IERC20(seigniorage_token).balanceOf(user_wallet);
      user_native_amount = user_wallet.balance;
      if (own_wallet_balance_gaslimit_correction && user_wallet == msg.sender) { user_native_amount += tx.gasprice * gaslimit; }
      user_native_value = user_native_amount * native_price / chainlink_precision;
      user_stable_amount = IERC20(stable_token).balanceOf(user_wallet);
      user_stable_value = user_stable_amount * stable_price / chainlink_precision;
      uint256 pair_stables = IERC20(stable_token).balanceOf(stable_pair) * token_precision;
      uint256 pair_seigniorage_tokens = IERC20(seigniorage_token).balanceOf(stable_pair);
      amm_seigniorage_stable_ratio = pair_stables / pair_seigniorage_tokens;
      amm_seigniorage_stable_price = pair_stables * stable_price / pair_seigniorage_tokens / chainlink_precision;
      user_seigniorage_value = user_seigniorage_balance * amm_seigniorage_stable_price / token_precision;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;
interface IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IChainlinkOracle {
    function latestAnswer() external view returns (uint256);
}