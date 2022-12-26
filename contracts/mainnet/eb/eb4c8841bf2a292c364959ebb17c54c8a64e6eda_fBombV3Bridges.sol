/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Fantom Bomb, LZ ERC 20 for BOMB/wBOMB
 * @author Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice UUPS 1822 update for burn(), burnFrom(), and update approvals
 * @custom:change-log line 3 of traverseChains() if (_amount >= userBal) => if (_amount > userBal)
 * @custom:change-log burn + burnFrom added from eip/20/IERC20Burnable.sol
 * @custom:change-log update transfer + transferFrom + traverseChains - Approve/Burn update (lib20v2)
 * @custom:dev-notice maintain checks/effect/interactions on all burn functions
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./fBombV2Bridges.sol";
import "./lib/Safe20.sol";
import "./lib/20.sol";
import "./lib/Lists.sol";
import "./eip/20/IERC20Burnable.sol";

contract fBombV3Bridges is fBombV2Bridges
                         , IERC20Burnable {

  using Lib20 for Lib20.Token;
  using Lists for Lists.Access;
  using Safe20 for IERC20;

  /// @dev transfer
  /// @return success
  /// @notice Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
  ///         The function SHOULD throw if the message caller’s account balance does not have enough
  ///         tokens to spend.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transfer(
    address _to
  , uint256 _value
  ) external
    virtual
    override 
    returns (bool success) {
    uint256 balanceUser = this.balanceOf(msg.sender);
    if (_to == address(0)) {
      revert MaxSplaining({
        reason: "Max20: to address(0)"
      });
    } else if (_value > balanceUser) {
      revert MaxSplaining({
        reason: "Max20: issuficient balance"
      });
    } else {
      if (taxExempt.onList(_to) || taxExempt.onList(msg.sender)) {
        success = token20.doTransfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
      } else {
        uint256 transValue = _value * 99 / 100;
        success = token20.doTransfer(msg.sender, _to, transValue);
        emit Transfer(msg.sender, _to, transValue);
        token20.burn(msg.sender, _value - transValue);
        emit Transfer(msg.sender, address(0), _value - transValue);
      }
    }
  }

  /// @dev transferFrom
  /// @return success
  /// @notice The transferFrom method is used for a withdraw workflow, allowing contracts to transfer
  ///         tokens on your behalf. This can be used for example to allow a contract to transfer
  ///         tokens on your behalf and/or to charge fees in sub-currencies. The function SHOULD
  ///         throw unless the _from account has deliberately authorized the sender of the message
  ///         via some mechanism.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transferFrom(
    address _from
  , address _to
  , uint256 _value
  ) external
    virtual
    override 
    returns (bool success) {
    uint256 balanceUser = this.balanceOf(_from);
    uint256 approveBal = this.allowance(_from, msg.sender);
    if (_from == address(0) || _to == address(0)) {
      revert MaxSplaining({
        reason: "Max20: to/from address(0)"
      });
    } else if (_value > balanceUser) {
      revert MaxSplaining({
        reason: "Max20: issuficient balance"
      });
    } else if (_value > approveBal) {
      revert MaxSplaining({
        reason: "Max20: not approved to spend _value"
      });
    } else {
      if (taxExempt.onList(_to) || taxExempt.onList(_from)) {
        success = token20.doTransfer(_from, _to, _value);
        emit Transfer(_from, _to, _value);
        token20.setApprove(_from, msg.sender, approveBal - _value);
        emit Approval(_from, msg.sender, approveBal - _value);
      } else {
        uint256 transValue = _value * 99 / 100;
        success = token20.doTransfer(_from, _to, transValue);
        emit Transfer(_from, _to, transValue);
        token20.burn(_from, _value - transValue);
        emit Transfer(_from, address(0), _value - transValue);
        token20.setApprove(_from, msg.sender, approveBal - _value);
        emit Approval(_from, msg.sender, approveBal - _value);
      }
    }
  }

  /// @dev burn
  /// @return success
  /// @notice Burns _value amount of tokens to address _to, and MUST fire the Transfer event.
  ///         The function SHOULD throw if the message caller’s account balance does not have enough
  ///         tokens to burn.
  /// @notice Note burn of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function burn(
    uint256 _value
  ) external
    virtual
    override
    returns (bool success) {
    uint256 balanceUser = this.balanceOf(msg.sender);
    if (_value > balanceUser) {
      revert MaxSplaining({
        reason: "Max20: issuficient balance"
      });
    } else {
      token20.burn(msg.sender, _value);
      success = true;
      emit Transfer(msg.sender, address(0), _value);
    }
  }

  /// @dev burnFrom
  /// @return success
  /// @notice The burnFrom method is used for a burn workflow, allowing contracts to burn
  ///         tokens on your behalf. This can be used for example to allow a contract to burn
  ///         tokens on your behalf and/or to charge fees in sub-currencies. The function SHOULD
  ///         throw unless the _from account has deliberately authorized the sender of the message
  ///         via some mechanism.
  /// @notice Note burn of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function burnFrom(
    address _from
  , uint256 _value
  ) external
    virtual
    override
    returns (bool success) {
    uint256 balanceUser = this.balanceOf(_from);
    uint256 approveBal = this.allowance(_from, msg.sender);
    if (_from == address(0)) {
      revert MaxSplaining({
        reason: "Max20: from address(0)"
      });
    } else if (_value > balanceUser) {
      revert MaxSplaining({
        reason: "Max20: issuficient balance"
      });
    } else if (_value > approveBal) {
      revert MaxSplaining({
        reason: "Max20: not approved to spend _value"
      });
    } else {
      token20.burn(_from, _value);
      success = true;
      emit Transfer(_from, address(0), _value);
      token20.setApprove(_from, msg.sender, approveBal - _value);
      emit Approval(_from, msg.sender, approveBal - _value);
    }
  }

  // @notice: This function transfers the ft from your address on the 
  //          source chain to the same address on the destination chain
  // @param _chainId: the uint16 of desination chain (see LZ docs)
  // @param _amount: amount to be sent
  function traverseChains(
    uint16 _chainId
  , uint256 _amount
  ) public
    virtual
    payable 
    override {
    uint256 userBal = token20.getBalanceOf(msg.sender);
    if (_amount > userBal) {
      revert MaxSplaining({
        reason: "Max20: issuficient balance"
      });
    }
    if (trustedRemoteLookup[_chainId].length == 0) {
      revert MaxSplaining({
        reason: "Token: TR not set"
      });
    }

    // set the amout to burn and send to treasury
    uint256 onePer = _amount / 100;
    uint256 toTraverse = _amount - (onePer * 2);

    // burn FT, eliminating it from circulation on src chain
    token20.burn(msg.sender, _amount - onePer);
    emit Transfer(msg.sender, address(0), _amount - onePer);
    token20.doTransfer(msg.sender, treasury, onePer);
    emit Transfer(msg.sender, treasury, onePer);

    // abi.encode() the payload with the values to send
    bytes memory payload = abi.encode(
                             msg.sender
                           , toTraverse);

    // encode adapterParams to specify more gas for the destination
    uint16 version = 1;
    bytes memory adapterParams = abi.encodePacked(
                                   version
                                 , gasForDestinationLzReceive);

    // get the fees we need to pay to LayerZero + Relayer to cover message delivery
    // you will be refunded for extra gas paid
    (uint messageFee, ) = endpoint.estimateFees(
                            _chainId
                          , address(this)
                          , payload
                          , false
                          , adapterParams);

    // revert this transaction if the fees are not met
    if (messageFee > msg.value) {
      revert MaxSplaining({
        reason: "Token: message fee low"
      });
    }

    // send the transaction to the endpoint
    endpoint.send{value: msg.value}(
      _chainId,                           // destination chainId
      trustedRemoteLookup[_chainId],      // destination address of nft contract
      payload,                            // abi.encoded()'ed bytes
      payable(msg.sender),                // refund address
      address(0x0),                       // 'zroPaymentAddress' unused for this
      adapterParams                       // txParameters 
    );
  }
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: [Not an EIP]: MaxFlow's 173/Dev/Roles Interface
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Interface for MaxAccess
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./IMAX173.sol";
import "./IMAXDEV.sol";
import "./IRoles.sol";

interface MaxAccess is IMAX173
                     , IMAXDEV
                     , IRoles {

  ///@dev this just imports all 3 and pushes to Implementation

}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: [Not an EIP]: Contract Roles Standard
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Interface for MaxAccess version of Roles
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "../../eip/165/IERC165.sol";

interface IRoles is IERC165 {

  /// @dev Returns `true` if `account` has been granted `role`.
  /// @param role: Bytes4 of a role
  /// @param account: Address to check
  /// @return bool true/false if account has role
  function hasRole(
    bytes4 role
  , address account
  ) external
    view
    returns (bool);

  /// @dev Returns the admin role that controls a role
  /// @param role: Role to check
  /// @return admin role
  function getRoleAdmin(
    bytes4 role
  ) external
    view 
    returns (bytes4);

  /// @dev Grants `role` to `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to give role to
  function grantRole(
    bytes4 role
  , address account
  ) external;

  /// @dev Revokes `role` from `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to revoke role from
  function revokeRole(
    bytes4 role
  , address account
  ) external;

  /// @dev Renounces `role` from `account`
  /// @param role: Bytes4 of a role
  function renounceRole(
    bytes4 role
  ) external;
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#* 
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=: 
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%* 
 *
 * @title: [Not an EIP]: Contract Developer Standard
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Interface for onlyDev() role
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "../../eip/165/IERC165.sol";

interface IMAXDEV is IERC165 {

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @return Developer of contract
  function developer()
    external
    view
    returns (address);

  /// @dev This renounces your role as onlyDev()
  function renounceDeveloper()
    external;

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @param newDeveloper: addres of new pending Developer role
  function transferDeveloper(
    address newDeveloper
  ) external;

  /// @dev This accepts the push-pull method of onlyDev()
  function acceptDeveloper()
    external;

  /// @dev This declines the push-pull method of onlyDev()
  function declineDeveloper()
    external;

  /// @dev This starts the push-pull method of onlyDev()
  /// @param newDeveloper: addres of new pending developer role
  function pushDeveloper(
    address newDeveloper
  ) external;

}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#* 
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=: 
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%* 
 *
 * @title:  EIP-173: Contract Ownership Standard, MaxFlowO2's extension
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Interface for enhancing EIP-173
 * @custom:change-log UUPS Upgradable
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "../../eip/173/IERC173.sol";

interface IMAX173 is IERC173 {

  /// @dev This is the classic "EIP-173" method of renouncing onlyOwner()  
  function renounceOwnership()
    external;

  /// @dev This accepts the push-pull method of onlyOwner()
  function acceptOwnership()
    external;

  /// @dev This declines the push-pull method of onlyOwner()
  function declineOwnership()
    external;

  /// @dev This starts the push-pull method of onlyOwner()
  /// @param newOwner: addres of new pending owner role
  function pushOwnership(
    address newOwner
  ) external;

}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: ILayerZeroUserApplicationConfig.sol
 * @author: LayerZero
 * @notice: Interface for LayerZeroUserApplicationConfig
 * OG Source: https://etherscan.io/address/0xa74ae2c6fca0cedbaef30a8ceef834b247186bcf#code
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
  // @notice set the configuration of the LayerZero messaging library of the specified version
  // @param _version - messaging library version
  // @param _chainId - the chainId for the pending config change
  // @param _configType - type of configuration. every messaging library has its own convention.
  // @param _config - configuration in the bytes. can encode arbitrary content.
  function setConfig(
    uint16 _version
  , uint16 _chainId
  , uint _configType
  , bytes calldata _config
  ) external;

  // @notice set the send() LayerZero messaging library version to _version
  // @param _version - new messaging library version
  function setSendVersion(
    uint16 _version
  ) external;

  // @notice set the lzReceive() LayerZero messaging library version to _version
  // @param _version - new messaging library version
  function setReceiveVersion(
    uint16 _version
  ) external;

  // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
  // @param _srcChainId - the chainId of the source chain
  // @param _srcAddress - the contract address of the source contract at the source chain
  function forceResumeReceive(
    uint16 _srcChainId
  , bytes calldata _srcAddress
  ) external;
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: ILayerZeroReceiver.sol
 * @author: LayerZero
 * @notice: Interface for LayerZeroReceiver
 * OG Source: https://etherscan.io/address/0xa74ae2c6fca0cedbaef30a8ceef834b247186bcf#code
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ILayerZeroReceiver {

  // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function lzReceive(
    uint16 _srcChainId
  , bytes calldata _srcAddress
  , uint64 _nonce
  , bytes calldata _payload
  ) external;

}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: ILayerZeroEndpoint.sol
 * @author: LayerZero
 * @notice: Interface for LayerZeroEndpoint
 * OG Source: https://etherscan.io/address/0xa74ae2c6fca0cedbaef30a8ceef834b247186bcf#code
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
  // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
  // @param _dstChainId - the destination chain identifier
  // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
  // @param _payload - a custom bytes payload to send to the destination contract
  // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
  // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
  // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
  function send(
    uint16 _dstChainId
  , bytes calldata _destination
  , bytes calldata _payload
  , address payable _refundAddress
  , address _zroPaymentAddress
  , bytes calldata _adapterParams
  ) external
    payable;

  // @notice used by the messaging library to publish verified payload
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source contract (as bytes) at the source chain
  // @param _dstAddress - the address on destination chain
  // @param _nonce - the unbound message ordering nonce
  // @param _gasLimit - the gas limit for external contract execution
  // @param _payload - verified payload to send to the destination contract
  function receivePayload(
    uint16 _srcChainId
  , bytes calldata _srcAddress
  , address _dstAddress
  , uint64 _nonce
  , uint _gasLimit
  , bytes calldata _payload
  ) external;

  // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  function getInboundNonce(
    uint16 _srcChainId
  , bytes calldata _srcAddress
  ) external
    view
    returns (uint64);

  // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
  // @param _srcAddress - the source chain contract address
  function getOutboundNonce(
    uint16 _dstChainId
  , address _srcAddress
  ) external
    view
    returns (uint64);

  // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
  // @param _dstChainId - the destination chain identifier
  // @param _userApplication - the user app address on this EVM chain
  // @param _payload - the custom message to send over LayerZero
  // @param _payInZRO - if false, user app pays the protocol fee in native token
  // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
  function estimateFees(
    uint16 _dstChainId
  , address _userApplication
  , bytes calldata _payload
  , bool _payInZRO
  , bytes calldata _adapterParam
  ) external
    view
    returns (
    uint nativeFee
  , uint zroFee);

  // @notice get this Endpoint's immutable source identifier
  function getChainId()
    external
    view
    returns (uint16);

  // @notice the interface to retry failed message on this Endpoint destination
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  // @param _payload - the payload to be retried
  function retryPayload(
    uint16 _srcChainId
  , bytes calldata _srcAddress
  , bytes calldata _payload
  ) external;

  // @notice query if any STORED payload (message blocking) at the endpoint.
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  function hasStoredPayload(
    uint16 _srcChainId
  , bytes calldata _srcAddress
  ) external
    view
    returns (bool);

  // @notice query if the _libraryAddress is valid for sending msgs.
  // @param _userApplication - the user app address on this EVM chain
  function getSendLibraryAddress(
    address _userApplication
  ) external
    view
    returns (address);

  // @notice query if the _libraryAddress is valid for receiving msgs.
  // @param _userApplication - the user app address on this EVM chain
  function getReceiveLibraryAddress(
    address _userApplication
  ) external
    view
    returns (address);

  // @notice query if the non-reentrancy guard for send() is on
  // @return true if the guard is on. false otherwise
  function isSendingPayload()
    external
    view
    returns (bool);

  // @notice query if the non-reentrancy guard for receive() is on
  // @return true if the guard is on. false otherwise
  function isReceivingPayload()
    external
    view
    returns (bool);

  // @notice get the configuration of the LayerZero messaging library of the specified version
  // @param _version - messaging library version
  // @param _chainId - the chainId for the pending config change
  // @param _userApplication - the contract address of the user application
  // @param _configType - type of configuration. every messaging library has its own convention.
  function getConfig(
    uint16 _version
  , uint16 _chainId
  , address _userApplication
  , uint _configType
  ) external
    view
    returns (bytes memory);

  // @notice get the send() LayerZero messaging library version
  // @param _userApplication - the contract address of the user application
  function getSendVersion(
    address _userApplication
  ) external
    view
    returns (uint16);

  // @notice get the lzReceive() LayerZero messaging library version
  // @param _userApplication - the contract address of the user application
  function getReceiveVersion(
    address _userApplication
  ) external
    view
    returns (uint16);
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: [Not an EIP] Safe ERC 20 Library
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Library makes use of bool success on transfer, transferFrom and approve of EIP 20
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >= 0.8.0 < 0.9.0;

import "../eip/20/IERC20.sol";

library Safe20 {

  error MaxSplaining(string reason);

  function safeTransfer(
    IERC20 token
  , address to
  , uint256 amount
  ) internal {
    if (!token.transfer(to, amount)) {
      revert MaxSplaining({
        reason: "Safe20: token.transfer failed"
      });
    }
  }

  function safeTransferFrom(
    IERC20 token
  , address from
  , address to
  , uint256 amount
  ) internal {
    if (!token.transferFrom(from, to, amount)) {
      revert MaxSplaining({
        reason: "Safe20: token.transferFrom failed"
      });
    }
  }

  function safeApprove(
    IERC20 token
  , address spender
  , uint256 amount
  ) internal {
    if (!token.approve(spender, amount)) {
      revert MaxSplaining({
        reason: "Safe20: token.approve failed"
      });
    }
  }
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Roles.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Library for MaxAcess.sol
 * @custom:error-code Roles:1 User has role already
 * @custom:error-code Roles:2 User does not have role to revoke
 * @custom:change-log custom errors added above
 * @custom:change-log cleaned up variables
 * @custom:change-log internal -> internal/internal
 *
 * Include with 'using Roles for Roles.Role;'
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

library Roles {

  bytes4 constant internal DEVS = 0xca4b208b;
  bytes4 constant internal OWNERS = 0x8da5cb5b;
  bytes4 constant internal ADMIN = 0xf851a440;

  struct Role {
    mapping(address => mapping(bytes4 => bool)) bearer;
    address owner;
    address developer;
    address admin;
  }

  event RoleChanged(bytes4 _role, address _user, bool _status);
  event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event DeveloperTransferred(address indexed previousDeveloper, address indexed newDeveloper);

  error Unauthorized();
  error MaxSplaining(string reason);

  function add(
    Role storage role
  , bytes4 userRole
  , address account
  ) internal {
    if (account == address(0)) {
      revert Unauthorized();
    } else if (has(role, userRole, account)) {
      revert MaxSplaining({
        reason: "Roles:1"
      });
    }
    role.bearer[account][userRole] = true;
    emit RoleChanged(userRole, account, true);
  }

  function remove(
    Role storage role
  , bytes4 userRole
  , address account
  ) internal {
    if (account == address(0)) {
      revert Unauthorized();
    } else if (!has(role, userRole, account)) {
      revert MaxSplaining({
        reason: "Roles:2"
      });
    }
    role.bearer[account][userRole] = false;
    emit RoleChanged(userRole, account, false);
  }

  function has(
    Role storage role
  , bytes4  userRole
  , address account
  ) internal
    view
    returns (bool) {
    if (account == address(0)) {
      revert Unauthorized();
    }
    return role.bearer[account][userRole];
  }

  function setAdmin(
    Role storage role
  , address account
  ) internal {
    if (has(role, ADMIN, account)) {
      address old = role.admin;
      role.admin = account;
      emit AdminTransferred(old, role.admin);
    } else if (account == address(0)) {
      address old = role.admin;
      role.admin = account;
      emit AdminTransferred(old, role.admin);
    } else {
      revert Unauthorized();
    }
  }

  function setDeveloper(
    Role storage role
  , address account
  ) internal {
    if (has(role, DEVS, account)) {
      address old = role.developer;
      role.developer = account;
      emit DeveloperTransferred(old, role.developer);
    } else if (account == address(0)) {
      address old = role.admin;
      role.admin = account;
      emit AdminTransferred(old, role.admin);
    } else {
      revert Unauthorized();
    }
  }

  function setOwner(
    Role storage role
  , address account
  ) internal {
    if (has(role, OWNERS, account)) {
      address old = role.owner;
      role.owner = account;
      emit OwnershipTransferred(old, role.owner);
    } else if (account == address(0)) {
      address old = role.admin;
      role.admin = account;
      emit AdminTransferred(old, role.admin);
    } else {
      revert Unauthorized();
    }
  }

  function getAdmin(
    Role storage role
  ) internal 
    view
    returns (address) {
    return role.admin;
  }

  function getDeveloper(
    Role storage role
  ) internal
    view
    returns (address) {
    return role.developer;
  }

  function getOwner(
    Role storage role
  ) internal
    view
    returns (address) {
    return role.owner;
  }
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: [Not an EIP]: Access lists
 * @author: @MaxFlowO2 on bird app/GitHub
 * @dev Formerly whitelists, now allowlist, or whatever it's called.
 * @custom:change-log removed end variable/functions (un-needed)
 * @custom:change-log variables renamed from lib whitelist
 * @custom:change-log internal -> internal
 * @custom:error-code Lists:1 "(user) is already whitelisted."
 * @custom:error-code Lists:2 "(user) is not whitelisted."
 * @custom:error-code Lists:3 "Whitelist already enabled."
 * @custom:error-code Lists:4 "Whitelist already disabled."
 * @custom:change-log added custom error codes
 * @custom:change-log removed import "./Strings.sol"; (un-needed)
 *
 * Include with 'using Lists for Lists.Access;'
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./CountersV2.sol";

library Lists {

  using CountersV2 for CountersV2.Counter;

  event ListChanged(bool _old, bool _new, address _address);
  event ListStatus(bool _old, bool _new);

  error MaxSplaining(string reason);

  struct Access {
    bool _status;
    CountersV2.Counter added;
    CountersV2.Counter removed;
    mapping(address => bool) allowed;
  }

  function add(
    Access storage list
  , address user
  ) internal {
    if (list.allowed[user]) {
      revert  MaxSplaining({
        reason : "Lists:1"
      });
    }
    // since now all previous values are false no need for another variable
    // and add them to the list!
    list.allowed[user] = true;
    // increment counter
    list.added.increment();
    // emit event
    emit ListChanged(false, list.allowed[user], user);
  }

  function remove(
    Access storage list
  , address user
  ) internal {
    if (!list.allowed[user]) {
      revert  MaxSplaining({
        reason : "Lists:2"
      });
    }
    // since now all previous values are true no need for another variable
    // and remove them from the list!
    list.allowed[user] = false;
    // increment counter
    list.removed.increment();
    // emit event
    emit ListChanged(true, list.allowed[user], user);
  }

  function enable(
    Access storage list
  ) internal {
    if (list._status) {
      revert  MaxSplaining({
        reason : "Lists:3"
      });
    }
    list._status = true;
    emit ListStatus(false, list._status);
  }

  function disable(
    Access storage list
  ) internal {
    if (!list._status) {
      revert  MaxSplaining({
        reason : "Lists:4"
      });
    }
    list._status = false;
    emit ListStatus(true, list._status);
  }

  function status(
    Access storage list
  ) internal
    view
    returns (bool) {
    return list._status;
  }

  function totalAdded(
    Access storage list
  ) internal
    view
    returns (uint) {
    return list.added.current();
  }

  function totalRemoved(
    Access storage list
  ) internal
    view
    returns (uint) {
    return list.removed.current();
  }

  function onList(
    Access storage list
  , address user
  ) internal
    view
    returns (bool) {
    return list.allowed[user];
  }
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: CountersV2.sol
 * @author Matt Condon (@shrugs)
 * @notice Provides counters that can only be incremented, decremented, reset or set. 
 * This can be used e.g. to track the number of elements in a mapping, issuing ERC721 ids
 * or counting request ids.
 * @custom:change-log MIT -> Apache-2.0
 * @custom:change-log Edited for more NFT functionality added .set(uint)
 * @custom:change-log added event CounterNumberChangedTo(uint _number).
 * @custom:change-log added error MaxSplaining(string reason).
 * @custom:change-log internal -> internal functions
 * @custom:error-code CountersV2:1 "No negatives in uints" - overflow protection
 *
 * Include with `using CountersV2 for CountersV2.Counter;`
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

library CountersV2 {

  struct Counter {
    uint256 value;
  }

  event CounterNumberChangedTo(uint _number);

  error MaxSplaining(string reason);

  function current(
    Counter storage counter
  ) internal
    view
    returns (uint256) {
    return counter.value;
  }

  function increment(
    Counter storage counter
  ) internal {
    unchecked {
      ++counter.value;
    }
  }

  function decrement(
    Counter storage counter
  ) internal {
    if (counter.value == 0) {
      revert MaxSplaining({
        reason : "CountersV2:1"
      });
    }
    unchecked {
      --counter.value;
    }
  }

  function reset(
    Counter storage counter
  ) internal {
    counter.value = 0;
    emit CounterNumberChangedTo(counter.value);
  }

  function set(
    Counter storage counter
  , uint number
  ) internal {
    counter.value = number;
    emit CounterNumberChangedTo(counter.value);
  }  
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Library 20
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Library for EIP 20
 * @custom:change-log Custom errors added above
 *
 * Include with 'using Lib20 for Lib20.Token;'
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

library Lib20 {

  struct Token {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    uint256 totalSupply;
    uint8 decimals;
    string name;
    string symbol;
  }

  error MaxSplaining(string reason);

  function setName(
    Token storage token
  , string memory newName
  ) internal {
    token.name = newName;
  }

  function getName(
    Token storage token
  ) internal
    view
    returns (string memory) {
    return token.name;
  }

  function setSymbol(
    Token storage token
  , string memory newSymbol
  ) internal {
    token.symbol = newSymbol;
  }

  function getSymbol(
    Token storage token
  ) internal
    view
    returns (string memory) {
    return token.symbol;
  }

  function setDecimals(
    Token storage token
  , uint8 newDecimals
  ) internal {
    token.decimals = newDecimals;
  }

  function getDecimals(
    Token storage token
  ) internal
    view
    returns (uint8) {
    return token.decimals;
  }

  function getTotalSupply(
    Token storage token
  ) internal
    view
    returns (uint256) {
    return token.totalSupply;
  }

  function getBalanceOf(
    Token storage token
  , address owner
  ) internal
    view
    returns (uint256) {
    return token.balances[owner];
  }

  function doTransfer(
    Token storage token
  , address from
  , address to
  , uint256 value
  ) internal
    returns (bool success) {
    uint256 fromBal = getBalanceOf(token, from);
    if (value > fromBal) {
      revert MaxSplaining({
        reason: "Max20:1"
      });
    }
    unchecked {
      token.balances[from] -= value;
      token.balances[to] += value;
    }
    return true;
  }

  function getAllowance(
    Token storage token
  , address owner
  , address spender
  ) internal 
    view
    returns (uint256) {
    return token.allowances[owner][spender];
  }

  function setApprove(
    Token storage token
  , address owner
  , address spender
  , uint256 amount
  ) internal 
    returns (bool) {
    token.allowances[owner][spender] = amount;
    return true;
  }

  function mint(
    Token storage token
  , address account
  , uint256 amount
  ) internal {
    if (account == address(0)) {
      revert MaxSplaining({
        reason: "Max20:2"
      });
    }
    token.totalSupply += amount;
    unchecked {
      token.balances[account] += amount;
    }
  }

  function burn(
    Token storage token
  , address account
  , uint256 amount
  ) internal {
    uint256 accountBal = getBalanceOf(token, account);
    if (amount > amount) {
      revert MaxSplaining({
        reason: "Max20:1"
      });
    }
    unchecked {
      token.balances[account] = accountBal - amount;
      token.totalSupply -= amount;
    }
  }
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Fantom Bomb, LZ ERC 20 for BOMB/wBOMB on destination chains
 * @author Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice UUPS 1822 update for Traverse chains. 
 * @custom:change-log line 3 of traverseChains() if (_amount >= userBal) => if (_amount > userBal)
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./fAToken-bridges.sol";
import "./lib/Safe20.sol";
import "./lib/20.sol";

contract fBombV2Bridges is fTokenOC {

  using Lib20 for Lib20.Token;
  using Safe20 for IERC20;

  // @notice: This function transfers the ft from your address on the 
  //          source chain to the same address on the destination chain
  // @param _chainId: the uint16 of desination chain (see LZ docs)
  // @param _amount: amount to be sent
  function traverseChains(
    uint16 _chainId
  , uint256 _amount
  ) public
    virtual
    payable 
    override {
    uint256 userBal = token20.getBalanceOf(msg.sender);
    if (_amount > userBal) {
      revert Unauthorized();
    }
    if (trustedRemoteLookup[_chainId].length == 0) {
      revert MaxSplaining({
        reason: "Token: TR not set"
      });
    }

    // set the amout to burn and send to treasury
    uint256 onePer = _amount / 100;
    uint256 toTraverse = _amount - (onePer * 2);

    // burn FT, eliminating it from circulation on src chain
    token20.burn(msg.sender, _amount - onePer);
    emit Transfer(msg.sender, address(0), _amount - onePer);
    token20.doTransfer(msg.sender, treasury, onePer);
    emit Transfer(msg.sender, treasury, onePer);

    // abi.encode() the payload with the values to send
    bytes memory payload = abi.encode(
                             msg.sender
                           , toTraverse);

    // encode adapterParams to specify more gas for the destination
    uint16 version = 1;
    bytes memory adapterParams = abi.encodePacked(
                                   version
                                 , gasForDestinationLzReceive);

    // get the fees we need to pay to LayerZero + Relayer to cover message delivery
    // you will be refunded for extra gas paid
    (uint messageFee, ) = endpoint.estimateFees(
                            _chainId
                          , address(this)
                          , payload
                          , false
                          , adapterParams);

    // revert this transaction if the fees are not met
    if (messageFee > msg.value) {
      revert MaxSplaining({
        reason: "Token: message fee low"
      });
    }

    // send the transaction to the endpoint
    endpoint.send{value: msg.value}(
      _chainId,                           // destination chainId
      trustedRemoteLookup[_chainId],      // destination address of nft contract
      payload,                            // abi.encoded()'ed bytes
      payable(msg.sender),                // refund address
      address(0x0),                       // 'zroPaymentAddress' unused for this
      adapterParams                       // txParameters 
    );
  }
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Fantom Bomb, LZ ERC 20 for BOMB/wBOMB on destination chains
 * @author Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "./Max-20-UUPS-LZ.sol";
import "./lib/Safe20.sol";
import "./lib/20.sol";
import "./lib/Lists.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract fTokenOC is Initializable
                   , Max20ImplementationUUPSLZ
                   , UUPSUpgradeable {

  using Lib20 for Lib20.Token;
  using Lists for Lists.Access;
  using Safe20 for IERC20;

  function disable()
    external {
    _disableInitializers();
  }

  function initialize(
    string memory _name
  , string memory _symbol
  , address _admin
  , address _dev
  , address _owner
  ) initializer
    public {
      __Max20_init(_name, _symbol, 18,  _admin, _dev, _owner);
      __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(ADMIN)
    override
    {}

  function addExempt(
    address newAddress
  ) external
    virtual
    onlyDev() {
    taxExempt.add(newAddress);
  }

  function removeExempt(
    address newAddress
  ) external
    virtual
    onlyDev() {
    taxExempt.remove(newAddress);
  }

  /// @dev transfer
  /// @return success
  /// @notice Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
  ///         The function SHOULD throw if the message caller’s account balance does not have enough
  ///         tokens to spend.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transfer(
    address _to
  , uint256 _value
  ) external
    virtual
    override (Max20ImplementationUUPSLZ)
    returns (bool success) {
    if (_to == address(0)) {
      revert MaxSplaining({
        reason: "Max20: to address(0)"
      });
    } else {
      if (taxExempt.onList(_to) || taxExempt.onList(msg.sender)) {
        success = token20.doTransfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
      } else {
        uint256 transValue = _value * 99 / 100;
        success = token20.doTransfer(msg.sender, _to, transValue);
        emit Transfer(msg.sender, _to, transValue);
        token20.burn(msg.sender, _value - transValue);
        emit Transfer(msg.sender, address(0), _value - transValue);
      }
    }
  }

  /// @dev transferFrom
  /// @return success
  /// @notice The transferFrom method is used for a withdraw workflow, allowing contracts to transfer
  ///         tokens on your behalf. This can be used for example to allow a contract to transfer
  ///         tokens on your behalf and/or to charge fees in sub-currencies. The function SHOULD
  ///         throw unless the _from account has deliberately authorized the sender of the message
  ///         via some mechanism.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transferFrom(
    address _from
  , address _to
  , uint256 _value
  ) external
    virtual
    override (Max20ImplementationUUPSLZ)
    returns (bool success) {
    uint256 approveBal = this.allowance(_from, msg.sender);
    if (_from == address(0) || _to == address(0)) {
      revert MaxSplaining({
        reason: "Max20: to/from address(0)"
      });
    } else if (approveBal >= _value) {
      revert MaxSplaining({
        reason: "Max20: not approved to spend _value"
      });
    } else {
      if (taxExempt.onList(_to) || taxExempt.onList(_from)) {
        success = token20.doTransfer(_from, _to, _value);
        emit Transfer(_from, _to, _value);
      } else {
        uint256 transValue = _value * 99 / 100;
        success = token20.doTransfer(_from, _to, transValue);
        emit Transfer(_from, _to, transValue);
        token20.burn(_from, _value - transValue);
        emit Transfer(_from, address(0), _value - transValue);
      }
    }
  }

  function setTres(
    address newAddress
  ) external
    virtual
    onlyDev() {
    treasury = newAddress;
  }

  // @notice: This function transfers the ft from your address on the 
  //          source chain to the same address on the destination chain
  // @param _chainId: the uint16 of desination chain (see LZ docs)
  // @param _amount: amount to be sent
  function traverseChains(
    uint16 _chainId
  , uint256 _amount
  ) public
    virtual
    payable {
    uint256 userBal = token20.getBalanceOf(msg.sender);
    if (_amount >= userBal) {
      revert Unauthorized();
    }
    if (trustedRemoteLookup[_chainId].length == 0) {
      revert MaxSplaining({
        reason: "Token: TR not set"
      });
    }

    // set the amout to burn and send to treasury
    uint256 onePer = _amount / 100;
    uint256 toTraverse = _amount - (onePer * 2);

    // burn FT, eliminating it from circulation on src chain
    token20.burn(msg.sender, _amount - onePer);
    emit Transfer(msg.sender, address(0), _amount - onePer);
    token20.doTransfer(msg.sender, treasury, onePer);
    emit Transfer(msg.sender, treasury, onePer);

    // abi.encode() the payload with the values to send
    bytes memory payload = abi.encode(
                             msg.sender
                           , toTraverse);

    // encode adapterParams to specify more gas for the destination
    uint16 version = 1;
    bytes memory adapterParams = abi.encodePacked(
                                   version
                                 , gasForDestinationLzReceive);

    // get the fees we need to pay to LayerZero + Relayer to cover message delivery
    // you will be refunded for extra gas paid
    (uint messageFee, ) = endpoint.estimateFees(
                            _chainId
                          , address(this)
                          , payload
                          , false
                          , adapterParams);

    // revert this transaction if the fees are not met
    if (messageFee > msg.value) {
      revert MaxSplaining({
        reason: "Token: message fee low"
      });
    }

    // send the transaction to the endpoint
    endpoint.send{value: msg.value}(
      _chainId,                           // destination chainId
      trustedRemoteLookup[_chainId],      // destination address of nft contract
      payload,                            // abi.encoded()'ed bytes
      payable(msg.sender),                // refund address
      address(0x0),                       // 'zroPaymentAddress' unused for this
      adapterParams                       // txParameters 
    );
  }

  // @notice: just in case this fixed variable limits us from future integrations
  // @param newVal: new value for gas amount
  function setGasForDestinationLzReceive(
    uint newVal
  ) external onlyDev() {
    gasForDestinationLzReceive = newVal;
  }

  // @notice internal function to mint FT from migration
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function _LzReceive(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes memory _payload
  ) override
    internal {
    // decode
    (address toAddr, uint256 amount) = abi.decode(_payload, (address, uint256));

    // mint the tokens back into existence on destination chain
    token20.mint(toAddr, amount);
    emit Transfer(address(0), toAddr, amount);
  }

  // @notice: will return gas value for LZ
  // @return: uint for gas value
  function currentLZGas()
    external
    view
    returns (uint256) {
    return gasForDestinationLzReceive;
  }  
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: [Not an EIP]: MaxErrors, so I can import errors, anywhere minus libraries
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev Does not have an ERC165 return since no external/public functions
 * @custom:change-log abstract contract -> interface
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

interface MaxErrors {

  /// @dev this is Unauthorized(), basically a catch all, zero description
  /// @notice 0x82b42900 bytes4 of this
  error Unauthorized();

  /// @dev this is MaxSplaining(), giving you a reason, aka require(param, "reason")
  /// @param reason: Use the "Contract name: error"
  /// @notice 0x0661b792 bytes4 of this
  error MaxSplaining(
    string reason
  );

  /// @dev this is TooSoonJunior(), using times
  /// @param yourTime: should almost always be block.timestamp
  /// @param hitTime: the time you should have started
  /// @notice 0xf3f82ac5 bytes4 of this
  error TooSoonJunior(
    uint yourTime
  , uint hitTime
  );

  /// @dev this is TooLateBoomer(), using times
  /// @param yourTime: should almost always be block.timestamp
  /// @param hitTime: the time you should have ended
  /// @notice 0x43c540ef bytes4 of this
  error TooLateBoomer(
    uint yourTime
  , uint hitTime
  );

}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title:  EIP-20: Extension
 * @author: Unknown
 * @notice
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright and related rights waived via CC0.                               *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "../165/IERC165.sol";

interface IERC20Burnable is IERC165 {

  /// @dev burn
  /// @return success
  /// @notice Burns _value amount of tokens to address _to, and MUST fire the Transfer event.
  ///         The function SHOULD throw if the message caller’s account balance does not have enough
  ///         tokens to burn.
  /// @notice Note burn of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function burn(
    uint256 _value
  ) external
    returns (bool success);

  /// @dev burnFrom
  /// @return success
  /// @notice The burnFrom method is used for a burn workflow, allowing contracts to burn
  ///         tokens on your behalf. This can be used for example to allow a contract to burn
  ///         tokens on your behalf and/or to charge fees in sub-currencies. The function SHOULD
  ///         throw unless the _from account has deliberately authorized the sender of the message
  ///         via some mechanism.
  /// @notice Note burn of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function burnFrom(
    address _from
  , uint256 _value
  ) external
    returns (bool success);

}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title:  EIP-20: Token Standard, extension
 * @author: Unknown
 * @notice: n/a
 * @custom:change-log backwards compatability to EIP 165 added
 * @custom:change-log MIT -> Apache-2.0

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright and related rights waived via CC0.                               *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "../165/IERC165.sol";

interface IERC20Burn is IERC165 {

  /// @dev to burn ERC20 tokens
  /// @param amount uint256 amount of tokens to burn
  function burn(
    uint256 amount
  ) external;

  function deposit(uint256 amount) external returns (bool);
  function withdraw(uint256 amount) external returns (bool);
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title:  EIP-20: Token Standard 
 * @author: Fabian Vogelsteller, Vitalik Buterin
 * @dev The following standard allows for the implementation of a standard API for tokens within
 *      smart contracts. This standard provides basic functionality to transfer tokens, as well
 *      as allow tokens to be approved so they can be spent by another on-chain third party.
 * @custom:source https://eips.ethereum.org/EIPS/eip-20
 * @custom:change-log external -> external, string -> string memory (0.8.x)
 * @custom:change-log readability enhanced
 * @custom:change-log backwards compatability to EIP 165 added
 * @custom:change-log MIT -> Apache-2.0

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright and related rights waived via CC0.                               *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "../165/IERC165.sol";

interface IERC20 is IERC165 {

  /// @dev Transfer Event
  /// @notice MUST trigger when tokens are transferred, including zero value transfers.
  /// @notice A token contract which creates new tokens SHOULD trigger a Transfer event
  ///         with the _from address set to 0x0 when tokens are created.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /// @dev Approval Event
  /// @notice MUST trigger on any successful call to approve(address _spender, uint256 _value).
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return string memory returns the name of the token - e.g. "MyToken".
  function name()
    external
    view
    returns (string memory);

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return string memory returns the symbol of the token. E.g. “HIX”.
  function symbol()
    external
    view
    returns (string memory);

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return uint8 returns the number of decimals the token uses - e.g. 8, means to divide the
  ///         token amount by 100000000 to get its user representation.
  function decimals()
    external
    view
    returns (uint8);

  /// @dev totalSupply
  /// @return uint256 returns the total token supply.
  function totalSupply()
    external
    view
    returns (uint256);

  /// @dev balanceOf
  /// @return balance returns the account balance of another account with address _owner.
  function balanceOf(
    address _owner
  ) external
    view
    returns (uint256 balance);

  /// @dev transfer
  /// @return success
  /// @notice Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
  ///         The function SHOULD throw if the message caller’s account balance does not have enough
  ///         tokens to spend.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transfer(
    address _to
  , uint256 _value
  ) external
    returns (bool success);

  /// @dev transferFrom
  /// @return success
  /// @notice The transferFrom method is used for a withdraw workflow, allowing contracts to transfer
  ///         tokens on your behalf. This can be used for example to allow a contract to transfer
  ///         tokens on your behalf and/or to charge fees in sub-currencies. The function SHOULD
  ///         throw unless the _from account has deliberately authorized the sender of the message
  ///         via some mechanism.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transferFrom(
    address _from
  , address _to
  , uint256 _value
  ) external
    returns (bool success);

  /// @dev approve
  /// @return success
  /// @notice Allows _spender to withdraw from your account multiple times, up to the _value amount.
  ///         If this function is called again it overwrites the current allowance with _value.
  /// @notice To prevent attack vectors like the one described here and discussed here, clients
  ///         SHOULD make sure to create user interfaces in such a way that they set the allowance
  ///         first to 0 before setting it to another value for the same spender. THOUGH The contract
  ///         itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed
  ///         before
  function approve(
    address _spender
  , uint256 _value
  ) external
    returns (bool success);

  /// @dev allowance
  /// @return remaining uint256 of allowance remaining
  /// @notice Returns the amount which _spender is still allowed to withdraw from _owner.
  function allowance(
    address _owner
  , address _spender
  ) external
    view
    returns (uint256 remaining);

}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: EIP-173: Contract Ownership Standard
 * @author: Nick Mudge, Dan Finlay
 * @notice: This specification defines standard functions for owning or controlling a contract.
 *          the ERC-165 identifier for this interface is 0x7f5828d0
 * @custom:URI https://eips.ethereum.org/EIPS/eip-173
 * @custom:change-log MIT -> Apache-2.0
 * @custom:change-log readability modification
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright and related rights waived via CC0.                               *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "../../eip/165/IERC165.sol";

interface IERC173 is IERC165 {

  /// @dev This emits when ownership of a contract changes.    
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /// @notice Get the address of the owner    
  /// @return The address of the owner.
  function owner()
    view
    external
    returns(address);
	
  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract    
  function transferOwnership(
    address _newOwner
  ) external;	
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: EIP-165: Standard Interface Detection
 * @author: Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 * @dev Creates a standard method to publish and detect what interfaces a smart contract implements.
 * @custom:source https://eips.ethereum.org/EIPS/eip-165
 * @custom:change-log interface ERC165 -> interface IERC165
 * @custom:change-log readability enhanced
 * @custom:change-log MIT -> Apache-2.0

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright and related rights waived via CC0.                               *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

interface IERC165 {

  /// @notice Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @notice Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(
    bytes4 interfaceID
  ) external
    view
    returns (bool);
}

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title Max-20-UUPS-LZ-Implementation
 * @author Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev 
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./eip/20/IERC20.sol";
import "./eip/20/IERC20Burn.sol";
import "./lib/Safe20.sol";
import "./lib/20.sol";
import "./modules/access/MaxAccess.sol";
import "./lib/Roles.sol";
import "./lib/Lists.sol";
import "./lz/ILayerZeroReceiver.sol";
import "./lz/ILayerZeroEndpoint.sol";
import "./errors/MaxErrors.sol";

abstract contract Max20ImplementationUUPSLZ is Initializable
                                             , MaxErrors
                                             , MaxAccess
                                             , ILayerZeroReceiver
                                             , IERC20 {

  //////////////////////////////////////
  // Storage
  //////////////////////////////////////

  using Lib20 for Lib20.Token;
  using Lists for Lists.Access;
  using Roles for Roles.Role;
  using Safe20 for IERC20;

  Lib20.Token internal token20;
  Roles.Role internal contractRoles;
  Lists.Access internal taxExempt;

  bytes4 constant internal DEVS = 0xca4b208b;
  bytes4 constant internal PENDING_DEVS = 0xca4b208a; // DEVS - 1
  bytes4 constant internal OWNERS = 0x8da5cb5b;
  bytes4 constant internal PENDING_OWNERS = 0x8da5cb5a; // OWNERS - 1
  bytes4 constant internal ADMIN = 0xf851a440;

  address internal Token;
  address internal WToken;
  address internal treasury;

  //////////////////////////////////////
  // LayerZero Storage
  //////////////////////////////////////

  ILayerZeroEndpoint internal endpoint;

  struct FailedMessages {
    uint payloadLength;
    bytes32 payloadHash;
  }

  mapping(uint16 => mapping(bytes => mapping(uint => FailedMessages))) public failedMessages;
  mapping(uint16 => bytes) public trustedRemoteLookup;
  uint256 internal gasForDestinationLzReceive;

  event TrustedRemoteSet(uint16 _chainId, bytes _trustedRemote);
  event EndpointSet(address indexed _endpoint);
  event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

  ///////////////////////
  // MAX-20: Modifiers
  ///////////////////////

  modifier onlyRole(bytes4 role) {
    if (contractRoles.has(role, msg.sender) || contractRoles.has(ADMIN, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  modifier onlyOwner() {
    if (contractRoles.has(OWNERS, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  modifier onlyDev() {
    if (contractRoles.has(DEVS, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  ///////////////////////
  /// MAX-20: Internals
  ///////////////////////

  function __Max20_init(
    string memory _name
  , string memory _symbol
  , uint8 _decimals
  , address _admin
  , address _dev
  , address _owner
  ) internal 
    onlyInitializing() {
    token20.setName(_name);
    token20.setSymbol(_symbol);
    token20.setDecimals(_decimals);
    contractRoles.add(ADMIN, _admin);
    contractRoles.setAdmin(_admin);
    contractRoles.add(DEVS, _dev);
    contractRoles.setDeveloper(_dev);
    contractRoles.add(OWNERS, _owner);
    contractRoles.setOwner(_owner);
  }

  //////////////////////////
  // EIP-20: Token Standard
  //////////////////////////

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return string memory returns the name of the token - e.g. "MyToken".
  function name()
    external
    view
    virtual
    override
    returns (string memory) {
    return token20.getName();
  }

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return string memory returns the symbol of the token. E.g. “HIX”.
  function symbol()
    external
    view
    virtual
    override
    returns (string memory) {
    return token20.getSymbol();
  }

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return uint8 returns the number of decimals the token uses - e.g. 8, means to divide the
  ///         token amount by 100000000 to get its user representation.
  function decimals()
    external
    view
    virtual
    override
    returns (uint8) {
    return token20.getDecimals();
  }

  /// @dev totalSupply
  /// @return uint256 returns the total token supply.
  function totalSupply()
    external
    view
    virtual
    override
    returns (uint256) {
    return token20.getTotalSupply();
  }

  /// @dev balanceOf
  /// @return balance returns the account balance of another account with address _owner.
  function balanceOf(
    address _owner
  ) external
    view
    virtual
    override
    returns (uint256 balance) {
    balance = token20.getBalanceOf(_owner);
  }

  /// @dev transfer
  /// @return success
  /// @notice Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
  ///         The function SHOULD throw if the message caller’s account balance does not have enough
  ///         tokens to spend.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transfer(
    address _to
  , uint256 _value
  ) external
    virtual
    override
    returns (bool success) {
    if (_to == address(0)) {
      revert MaxSplaining({
        reason: "Max20: to address(0)"
      });
    } else {
      success = token20.doTransfer(msg.sender, _to, _value);
      emit Transfer(msg.sender, _to, _value);
    }
  }

  /// @dev transferFrom
  /// @return success
  /// @notice The transferFrom method is used for a withdraw workflow, allowing contracts to transfer
  ///         tokens on your behalf. This can be used for example to allow a contract to transfer
  ///         tokens on your behalf and/or to charge fees in sub-currencies. The function SHOULD
  ///         throw unless the _from account has deliberately authorized the sender of the message
  ///         via some mechanism.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transferFrom(
    address _from
  , address _to
  , uint256 _value
  ) external
    virtual
    override
    returns (bool success) {
    uint256 approveBal = this.allowance(_from, msg.sender);
    if (_from == address(0) || _to == address(0)) {
      revert MaxSplaining({
        reason: "Max20: to/from address(0)"
      });
    } else if (approveBal >= _value) {
      revert MaxSplaining({
        reason: "Max20: not approved to spend _value"
      });
    } else {
      success = token20.doTransfer(_from, _to, _value);
      emit Transfer(_from, _to, _value);
    }
  }

  /// @dev approve
  /// @return success
  /// @notice Allows _spender to withdraw from your account multiple times, up to the _value amount.
  ///         If this function is called again it overwrites the current allowance with _value.
  /// @notice To prevent attack vectors like the one described here and discussed here, clients
  ///         SHOULD make sure to create user interfaces in such a way that they set the allowance
  ///         first to 0 before setting it to another value for the same spender. THOUGH The contract
  ///         itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed
  ///         before
  function approve(
    address _spender
  , uint256 _value
  ) external
    virtual
    override
    returns (bool success) {
    success = token20.setApprove(msg.sender, _spender, _value);
    emit Approval(msg.sender, _spender, _value);
  }

  /// @dev allowance
  /// @return remaining uint256 of allowance remaining
  /// @notice Returns the amount which _spender is still allowed to withdraw from _owner.
  function allowance(
    address _owner
  , address _spender
  ) external
    view
    virtual
    override
    returns (uint256 remaining) {
    return token20.getAllowance(_owner, _spender);
  }

  ///////////////////
  /// LayerZero: NBR
  ///////////////////

  // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function lzReceive(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes memory _payload
  ) external
    override {
    if (msg.sender != address(endpoint)) {
      revert MaxSplaining({
        reason: "NBR:1"
      });
    }

    if (
      _srcAddress.length != trustedRemoteLookup[_srcChainId].length ||
      keccak256(_srcAddress) != keccak256(trustedRemoteLookup[_srcChainId])
    ) {
      revert MaxSplaining({
        reason: "NBR:2"
      });
    }

    // try-catch all errors/exceptions
    // having failed messages does not block messages passing
    try this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
      // do nothing
    } catch {
      // error or exception
      failedMessages[_srcChainId][_srcAddress][_nonce] = FailedMessages(_payload.length, keccak256(_payload));
      emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
    }
  }

  // @notice this is the catch all above (should be an internal?)
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function onLzReceive(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes memory _payload
  ) public {

    // only internal transaction
    if (msg.sender != address(this)) {
      revert MaxSplaining({
        reason: "NBR:3"
      });
    }

    // handle incoming message
    _LzReceive( _srcChainId, _srcAddress, _nonce, _payload);
  }

  // @notice internal function to do something in the main contract
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function _LzReceive(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes memory _payload
  ) virtual
    internal;

  // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
  // @param _dstChainId - the destination chain identifier
  // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
  // @param _payload - a custom bytes payload to send to the destination contract
  // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
  // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
  // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
  function _lzSend(
    uint16 _dstChainId
  , bytes memory _payload
  , address payable _refundAddress
  , address _zroPaymentAddress
  , bytes memory _txParam
  ) internal {
    endpoint.send{value: msg.value}(
      _dstChainId
    , trustedRemoteLookup[_dstChainId]
    , _payload, _refundAddress
    , _zroPaymentAddress
    , _txParam);
  }

  // @notice this is to retry a failed message on LayerZero
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  // @param _nonce - the ordered message nonce
  // @param _payload - the payload to be retried
  function retryMessage(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes calldata _payload
  ) external
    payable {
    // assert there is message to retry
    FailedMessages storage failedMsg = failedMessages[_srcChainId][_srcAddress][_nonce];
    if (failedMsg.payloadHash == bytes32(0)) {
      revert MaxSplaining({
        reason: "NBR:4"
      });
    }
    if (
      _payload.length != failedMsg.payloadLength ||
      keccak256(_payload) != failedMsg.payloadHash
    ) {
      revert MaxSplaining({
        reason: "NBR:5"
      });
    }

    // clear the stored message
    failedMsg.payloadLength = 0;
    failedMsg.payloadHash = bytes32(0);

    // execute the message. revert if it fails again
    this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }


  // @notice this is to set all valid incoming messages
  // @param _srcChainId - the source chain identifier
  // @param _trustedRemote - the source chain contract address
  function setTrustedRemote(
    uint16 _chainId
  , bytes calldata _trustedRemote
  ) external
    onlyDev() {
    trustedRemoteLookup[_chainId] = _trustedRemote;
    emit TrustedRemoteSet(_chainId, _trustedRemote);
  }

  // @notice this is to set all valid incoming messages
  // @param _srcChainId - the source chain identifier
  // @param _trustedRemote - the source chain contract address
  function setEndPoint(
    address newEndpoint
  ) external
    onlyDev() {
    endpoint = ILayerZeroEndpoint(newEndpoint);
    emit EndpointSet(newEndpoint);
  }

  /////////////////////////////////////////
  /// EIP-173: Contract Ownership Standard
  /////////////////////////////////////////

  /// @notice Get the address of the owner    
  /// @return The address of the owner.
  function owner()
    view
    external
    returns(address) {
    return contractRoles.getOwner();
  }
	
  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract    
  function transferOwnership(
    address _newOwner
  ) external
    onlyRole(OWNERS) {
    contractRoles.add(OWNERS, _newOwner);
    contractRoles.setOwner(_newOwner);
    contractRoles.remove(OWNERS, msg.sender);
  }

  ////////////////////////////////////////////////////////////////
  /// EIP-173: Contract Ownership Standard, MaxFlowO2's extension
  ////////////////////////////////////////////////////////////////

  /// @dev This is the classic "EIP-173" method of renouncing onlyOwner()  
  function renounceOwnership()
    external 
    onlyRole(OWNERS) {
    contractRoles.setOwner(address(0));
    contractRoles.remove(OWNERS, msg.sender);
  }

  /// @dev This accepts the push-pull method of onlyOwner()
  function acceptOwnership()
    external
    onlyRole(PENDING_OWNERS) {
    contractRoles.add(OWNERS, msg.sender);
    contractRoles.setOwner(msg.sender);
    contractRoles.remove(PENDING_OWNERS, msg.sender);
  }

  /// @dev This declines the push-pull method of onlyOwner()
  function declineOwnership()
    external
    onlyRole(PENDING_OWNERS) {
    contractRoles.remove(PENDING_OWNERS, msg.sender);
  }

  /// @dev This starts the push-pull method of onlyOwner()
  /// @param newOwner: addres of new pending owner role
  function pushOwnership(
    address newOwner
  ) external
    onlyRole(OWNERS) {
    contractRoles.add(PENDING_OWNERS, newOwner);
  }

  //////////////////////////////////////////////
  /// [Not an EIP]: Contract Developer Standard
  //////////////////////////////////////////////

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @return Developer of contract
  function developer()
    external
    view
    returns (address) {
    return contractRoles.getDeveloper();
  }

  /// @dev This renounces your role as onlyDev()
  function renounceDeveloper()
    external
    onlyRole(DEVS) {
    contractRoles.setDeveloper(address(0));
    contractRoles.remove(DEVS, msg.sender);
  }

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @param newDeveloper: addres of new pending Developer role
  function transferDeveloper(
    address newDeveloper
  ) external
    onlyRole(DEVS) {
    contractRoles.add(DEVS, newDeveloper);
    contractRoles.setDeveloper(newDeveloper);
    contractRoles.remove(DEVS, msg.sender);
  }

  /// @dev This accepts the push-pull method of onlyDev()
  function acceptDeveloper()
    external
    onlyRole(PENDING_DEVS) {
    contractRoles.add(DEVS, msg.sender);
    contractRoles.setDeveloper(msg.sender);
    contractRoles.remove(PENDING_DEVS, msg.sender);
  }

  /// @dev This declines the push-pull method of onlyDev()
  function declineDeveloper()
    external
    onlyRole(PENDING_DEVS) {
    contractRoles.remove(PENDING_DEVS, msg.sender);
  }

  /// @dev This starts the push-pull method of onlyDev()
  /// @param newDeveloper: addres of new pending developer role
  function pushDeveloper(
    address newDeveloper
  ) external
    onlyRole(DEVS) {
    contractRoles.add(PENDING_DEVS, newDeveloper);
  }

  //////////////////////////////////////////
  /// [Not an EIP]: Contract Roles Standard
  //////////////////////////////////////////

  /// @dev Returns `true` if `account` has been granted `role`.
  /// @param role: Bytes4 of a role
  /// @param account: Address to check
  /// @return bool true/false if account has role
  function hasRole(
    bytes4 role
  , address account
  ) external
    view
    returns (bool) {
    return contractRoles.has(role, account);
  }

  /// @dev Returns the admin role that controls a role
  /// @param role: Role to check
  /// @return admin role
  function getRoleAdmin(
    bytes4 role
  ) external
    view 
    returns (bytes4) {
    return ADMIN;
  }

  /// @dev Grants `role` to `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to give role to
  function grantRole(
    bytes4 role
  , address account
  ) external
    onlyRole(role) {
    if (role == PENDING_DEVS || role == PENDING_OWNERS) {
      revert Unauthorized();
    } else {
      contractRoles.add(role, account);
    }
  }

  /// @dev Revokes `role` from `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to revoke role from
  function revokeRole(
    bytes4 role
  , address account
  ) external
    onlyRole(role) {
    if (role == PENDING_DEVS || role == PENDING_OWNERS) {
      if (account == msg.sender) {
        contractRoles.remove(role, account);
      } else {
        revert Unauthorized();
      }
    } else {
      contractRoles.remove(role, account);
    }
  }

  /// @dev Renounces `role` from `account`
  /// @param role: Bytes4 of a role
  function renounceRole(
    bytes4 role
  ) external
    onlyRole(role) {
    contractRoles.remove(role, msg.sender);
  }


  //////////////////////////////////////////
  /// EIP-165: Standard Interface Detection
  //////////////////////////////////////////

  /// @dev Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @notice Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(
    bytes4 interfaceID
  ) external
    view
    virtual
    override
    returns (bool) {
    return (
      interfaceID == type(IERC173).interfaceId  ||
      interfaceID == type(IMAX173).interfaceId  ||
      interfaceID == type(IMAXDEV).interfaceId  ||
      interfaceID == type(IRoles).interfaceId  ||
      interfaceID == type(IERC20).interfaceId   
    );
  }
 
  uint256[35] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}