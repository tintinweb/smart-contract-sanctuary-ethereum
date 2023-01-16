/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: [EIP1155] Max-1155/2023 Gen 2 Demo
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Max-1155/2023 Gen 2 Demo
 * @custom:error-codes Max1155:1 => "Max1155: Mint to address(0)"
 * @custom:error-codes Max1155:2 => "Max1155: Burn from address(0)"
 * @custom:error-codes Max1155:3 => "Max1155: address(0) can not own tokens"
 * @custom:error-codes Max1155:4 => "Max1155: ids/amounts mismatch"
 * @custom:error-codes Max1155:5 => "Max1155: Not owner or approved for all"
 * @custom:error-codes Max1155:6 => "Max1155: Token id non-existant"
 * @custom:error-codes Max1155:7 => "Max1155: No tokens to minter"
 * @custom:error-codes Max1155:8 => "Max1155: catch reason.length == 0"
 * @custom:error-codes Max1155LZ:1 => "Max1155LZ: Not from set endpoint"
 * @custom:error-codes Max1155LZ:2 => "Max1155LZ: Not from trusted remote"
 * @custom:error-codes Max1155LZ:3 => "Max1155LZ: Internals only for try/catch"
 * @custom:error-codes Max1155LZ:4 => "Max1155LZ: Message not stored"
 * @custom:error-codes Max1155LZ:5 => "Max1155LZ: payload noes not match failed message payload"
 * @custom:error-codes Max1155LZ:6 => "Max1155LZ: trustedRemote not set for chainId"
 * @custom:error-codes Max1155LZ:7 => "Max1155LZ: msg.value below messageFee needed to traverse"
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

pragma solidity >=0.8.17 <0.9.0;

import "./Max-1155-UUPS-2981-LZ.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./modules/factory/IMinterFactory.sol";

contract ERC1155Demo is Initializable
                      , Max1155UUPS2981LZ
                      , UUPSUpgradeable {

  using Address for address;

  // EIP 1822 stuff

  function disable()
    external {
    _disableInitializers();
  }

  function initialize(
    string memory _name
  , string memory _uri
  , address _admin
  , address _dev
  , address _owner
  ) initializer
    public {
      __Max1155_init(_name, _uri, _admin, _dev, _owner);
      __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(ADMIN)
    override
    {}

  // Minting (demo purposes)

  function FactoryMint(
    address _to
  , uint256 _id
  , uint256 _amount
  , bytes memory _data
  ) external
    onlyRole(MINTER) {
    _mint(_to, _id, _amount, _data);
  }

  function FactoryMintBatch(
    address _to
  , uint256[] memory _ids
  , uint256[] memory _amounts
  , bytes memory _data
  ) external 
    onlyRole(MINTER) {
    _mintBatch(_to, _ids, _amounts, _data);
  }

  function FactoryGenesis(
    uint256 startingID
  , uint256 endingID
  ) external
    onlyDev() {
    address newProxy = IMinterFactory(factory)
                         .createByTransparentProxy(
                           address(this) 
                         , this.developer()
                         , address(this)
                         , startingID
                         , endingID
                         );
    _addMinterRole(newProxy);
  }

  function setFactory(
    address _factory
  ) external
    onlyDev() {
    factory = _factory;
  }

  // LZ Madness 

  /// @notice This function transfers the ft from your address on the 
  ///          source chain to the same address on the destination chain
  /// @param _chainId: the uint16 of desination chain (see LZ docs)
  /// @param _ids: uint256[] of all ids to be sent
  /// @param _amounts: uint256[] of all amounts to be sent
  function traverseChains(
    uint16 _chainId
  , uint256[] memory _ids
  , uint256[] memory _amounts
  ) public
    virtual
    payable {
    if (trustedRemoteLookup[_chainId].length == 0) {
      revert MaxSplaining({
        reason: "Max1155LZ:6"
      });
    }

    // burn 1155's, eliminating it from circulation on src chain
    _burnBatch(msg.sender, _ids, _amounts, "");

    // abi.encode() the payload with the values to send
    bytes memory payload = abi.encode(
                             msg.sender
                           , _ids
                           , _amounts);

    // encode adapterParams to specify more gas for the destination
    uint16 version = 1;
    bytes memory adapterParams = abi.encodePacked(
                                   version
                                 , this.currentLZGas(_ids.length));

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
        reason: "Max1155LZ:7"
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

  /// @notice just in case this fixed variable limits us from future integrations
  /// @param _newBase: new base amount (array length = 0) (180K)
  /// @param _newIncrement: additonal gas amount per +1 to array length (17.5k)
  function setGasForDestinationLzReceive(
    uint256 _newBase
  , uint256 _newIncrement
  ) external
    onlyDev() {
    gasForDestinationLzReceiveBase = _newBase;
    gasForDestinationLzReceiveIncrement = _newIncrement;
  }

  /// @notice internal function to mint FT from migration
  /// @param _srcChainId - the source endpoint identifier
  /// @param _srcAddress - the source sending contract address from the source chain
  /// @param _nonce - the ordered message nonce
  /// @param _payload - the signed payload is the UA bytes has encoded to be sent
  function _LzReceive(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes memory _payload
  ) override
    internal {
    // decode
    (address reciever, uint256[] memory ids, uint256[] memory amounts) = abi.decode(_payload, (address, uint256[], uint256[]));

    // mint the tokens back into existence on destination chain
    _mintBatch(reciever, ids, amounts, "");
  }

  /// @notice will return gas value for LZ Destination receive
  /// @param _length: Length of array to send
  /// @return uint for gas value (base for length 1, and ++increments per ++length)
  function currentLZGas(
    uint256 _length
  ) external
    view
    returns (uint256) {
    if (_length == 0) {
      revert Unauthorized();
    }
    return gasForDestinationLzReceiveBase + (gasForDestinationLzReceiveIncrement * (_length - 1));
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
 * @title: [EIP1822/1967] UUPS Proxy Factory, Minters for ERC1155/1822
 * @author: cryptogenics on medium, r4881t on GitHub
 * @notice source at https://r48b1t.medium.com/universal-upgrade-proxy-proxyfactory-a-modern-walkthroug>
 * @custom:change-log readability, comments added
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright waived under CC0                                                 *
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

pragma solidity >=0.8.17 <0.9.0;

import "../../eip/165/IERC165.sol";

interface IMinterFactory is IERC165 {

  function createByTransparentProxy(
    address _backend
  , address _dev
  , address _admin
  , uint256 _start
  , uint256 _end
  ) external
    returns (address);

  function deployedMinters()
    external
    view
    returns (address[] memory);

  function currentImplementation()
    external
    view
    returns (address);

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
 * @notice Interface for MaxAccess version of Roles
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
 * @title: EIP-2981: NFT Royalty Standard, admin extension
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice the ERC-165 identifier for this interface is unknown.
 * @custom:source https://eips.ethereum.org/EIPS/eip-2981
 * @custom:change-log MIT -> Apache-2.0
 *
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

import "../../eip/2981/IERC2981.sol";

interface IERC2981Admin is IERC2981 {

  /// @dev function (state storage) sets the royalty data for a token
  /// @param tokenId uint256 for the token
  /// @param receiver address for the royalty reciever for token
  /// @param permille uint16 for the permille of royalties 20 -> 2.0%
  function setRoyalties(
    uint256 tokenId
  , address receiver
  , uint16 permille
  ) external;

  /// @dev function (state storage) revokes the royalty data for a token
  /// @param tokenId uint256 for the token
  function revokeRoyalties(
    uint256 tokenId
  ) external;

  /// @dev function (state storage) sets the royalty data for a collection
  /// @param receiver address for the royalty reciever for token
  /// @param permille uint16 for the permille of royalties 20 -> 2.0%
  function setRoyalties(
    address receiver
  , uint16 permille
  ) external;

  /// @dev function (state storage) revokes the royalty data for a collection
  function revokeRoyalties()
    external;
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
 * @notice Interface for LayerZeroUserApplicationConfig
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
 * @notice Interface for LayerZeroReceiver
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
 * @notice Interface for LayerZeroEndpoint
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
 * @title: Strings
 * @author: OpenZeppelin
 * @notice Strings Library
 * @custom:source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.7.3/contracts/utils/StringsUpgradeable.sol
 * @custom:change-log Readable, External/Public, Removed code comments, MIT -> Apache-2.0
 * @custom:change-log Added MaxSplaining
 * @custom:error-code Str:1 "hex length insufficient"
 *
 * Include with 'using Strings for <insert type>'
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

library Strings {

  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
  uint8 private constant _ADDRESS_LENGTH = 20;

  error MaxSplaining(string reason);

  function toString(
    uint256 value
  ) internal
    pure
    returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function toHexString(
    uint256 value
  ) internal
    pure
    returns (string memory) {
    if (value == 0) {
      return "0x00";
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  function toHexString(
    uint256 value
  , uint256 length
  ) internal
    pure
    returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    if (value != 0) {
      revert MaxSplaining({
        reason: "Str:1"
      });
    }
    return string(buffer);
  }

  function toHexString(
    address addr
  ) internal
    pure
    returns (string memory) {
    return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
 * @notice Library for MaxAcess.sol
 * @custom:change-log cleaned up variables
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

  function add(
    Role storage role
  , bytes4 userRole
  , address account
  ) internal {
    if (account == address(0)) {
      revert Unauthorized();
    } else if (has(role, userRole, account)) {
      revert Unauthorized();
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
      revert Unauthorized();
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
      address old = role.developer;
      role.developer = account;
      emit DeveloperTransferred(old, role.developer);
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
      address old = role.owner;
      role.owner = account;
      emit OwnershipTransferred(old, role.owner);
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
 * @title: [Not an EIP]: Library for arrays
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice This adds functionality to arrays
 * Include with 'using Arrays for <input type>;'
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

library Arrays {

  function findIndex(
    uint256[] memory array
  , uint256 query
  ) internal
    pure
    returns (bool found, uint256 index) {
    uint256 len = array.length;
    for (uint x = 0; x < len;) {
      if (array[x] == query) {
        found = true;
        index = x;
      }
      unchecked { ++x; }
    }
  }

  function findIndex(
    bytes32[] memory array
  , bytes32 query
  ) internal
    pure
    returns (bool found, uint256 index) {
    uint256 len = array.length;
    for (uint x = 0; x < len;) {
      if (array[x] == query) {
        found = true;
        index = x;
      }
      unchecked { ++x; }
    }
  }

  function findIndex(
    address[] memory array
  , address query
  ) internal
    pure
    returns (bool found, uint256 index) {
    uint256 len = array.length;
    for (uint x = 0; x < len;) {
      if (array[x] == query) {
        found = true;
        index = x;
      }
      unchecked { ++x; }
    }
  }

  function toArray(
    uint256 query
  ) internal 
    pure
    returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = query;
    return array;
  }

  function toArray(
    bytes32 query
  ) internal
    pure
    returns (bytes32[] memory) {
    bytes32[] memory array = new bytes32[](1);
    array[0] = query;
    return array;
  }

  function toArray(
    address query
  ) internal
    pure
    returns (address[] memory) {
    address[] memory array = new address[](1);
    array[0] = query;
    return array;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Library 2981
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Library for EIP 2981
 * @custom:error-code R:1 Permille out of bounds
 * @custom:change-log Custom errors added above
 *
 * Include with 'using Lib2981 for Lib2981.Royalties;' -- unique per collection
 * Include with 'using Lib2981 for Lib2981.MappedRoyalties;' -- unique per token
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

library Lib2981c {

  struct Royalties {
    address receiver;
    uint16 permille;
  }

  event RoyaltiesSet(uint256 token, address recipient, uint16 value);
  event RoyaltiesSet(address recipient, uint16 value);

  error MaxSplaining(string reason);

  function setRoyalties(
    Royalties storage royalties
  , address receiver
  , uint16 permille
  ) internal {
    if (permille >= 1000 ||  permille == 0) {
      revert MaxSplaining({
        reason: "R:1"
      });
    }
    royalties.receiver = receiver;
    royalties.permille = permille;
    emit RoyaltiesSet(
           royalties.receiver
         , royalties.permille
         );
  }

  function revokeRoyalties(
    Royalties storage royalties
  ) internal {
    delete royalties.receiver;
    delete royalties.permille;
    emit RoyaltiesSet(
           royalties.receiver
         , royalties.permille
         );
  }

  function royaltyInfo(
    Royalties storage royalties
  , uint256 tokenId
  , uint256 salePrice
  ) internal
    view
    returns (
      address receiver
    , uint256 royaltyAmount
    ) {
    receiver = royalties.receiver;
    royaltyAmount = salePrice * royalties.permille / 1000;
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
 * @title: Library 1155
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice Library for EIP 1155
 * @custom:error-code Lib1155:1 "approve to caller"
 * @custom:error-code Lib1155:2 "zero address"
 * @custom:error-code Lib1155:3 "insufficient balance"
 * @custom:change-log Custom errors added above
 *
 * Include with 'using Lib1155 for Lib1155.Token;'
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

import "./Strings.sol";

library Lib1155 {

  using Strings for uint256;

  error MaxSplaining(string reason);

  struct Token {
    mapping(uint256 => mapping(address => uint256)) balances;
    mapping(address => mapping(address => bool)) operatorApprovals;
    mapping(uint256 => uint256) totalSupply;
    string name;
    string uri;
  }

  function getName(
    Token storage token
  ) internal
    view
    returns (string memory) {
    return token.name;
  }

  function setName(
    Token storage token
  , string memory newName
  ) internal {
    token.name = newName;
  }

  function getURI(
    Token storage token
  ) internal
    view
    returns (string memory) {
    return token.uri;
  }

  function setURI(
    Token storage token
  , string memory newURI
  ) internal {
    token.uri = newURI;
  }

  function getBalanceOf(
    Token storage token
  , address account
  , uint256 id
  ) internal
    view
    returns (uint256) {
    return token.balances[id][account];
  }

  function setApprovalForAll(
    Token storage token
  , address from
  , address operator
  , bool approved
  ) internal {
    if (from == operator) {
      revert MaxSplaining({
        reason: "Lib1155:1"
      });
    }
    token.operatorApprovals[from][operator] = approved;
  }

  function isApprovedForAll(
    Token storage token
  , address owner
  , address operator
  ) internal
    view
    returns (bool) {
    return token.operatorApprovals[owner][operator];
  }

  function doTransferFrom(
    Token storage token
  , address from
  , address to
  , uint256 id
  , uint256 amount
  ) internal {
    if (to == address(0)) {
      revert MaxSplaining({
        reason: "Lib1155:2"
      });
    }
    uint256 balCheck = token.balances[id][from];
    if (amount > balCheck) {
      revert MaxSplaining({
        reason: "Lib1155:3"
      });
    }
    unchecked {
      token.balances[id][from] = balCheck - amount;
    }
    token.balances[id][to] += amount;
  }

  function mint(
    Token storage token
  , address to
  , uint256 id
  , uint256 amount
  ) internal {
    if (to == address(0)) {
      revert MaxSplaining({
        reason: "Lib1155:2"
      });
    }
    token.balances[id][to] += amount;
  }

  function burn(
    Token storage token
  , address from
  , uint256 id
  , uint256 amount
  ) internal {
    if (from == address(0)) {
      revert MaxSplaining({
        reason: "Lib1155:2"
      });
    }
    uint256 balCheck = token.balances[id][from];
    if (amount > balCheck) {
      revert MaxSplaining({
        reason: "Lib1155:3"
      });
    }
    unchecked {
      token.balances[id][from] = balCheck - amount;
    }
  }

  function upSupply(
    Token storage token
  , uint256 id
  , uint256 amount
  ) internal {
    token.totalSupply[id] += amount;
  }

  function downSupply(
    Token storage token
  , uint256 id
  , uint256 amount
  ) internal {
    token.totalSupply[id] -= amount;
  }

  function tokenExists(
    Token storage token
  , uint256 id
  ) internal
    view
    returns (bool) {
    return token.totalSupply[id] > 0;
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
 * @title: ERC-721 Non-Fungible Token Standard, Token Receiver
 * @author: William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 * @notice the ERC-165 identifier for this interface is 0x150b7a02.
 * @custom:source https://eips.ethereum.org/EIPS/eip-721
 * @custom:change-log interface ERC721TokenReceiver -> interface IERC721TokenReceiver
 * @custom:change-log readability enhanced
 * @custom:change-log MIT -> Apache-2.0
 * @custom:change-log TypeError: Data location must be "memory" or "calldata" for parameter (line 60)
 *
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

interface IERC721TokenReceiver is IERC165 {

  /// @notice Handle the receipt of an NFT
  /// @notice The ERC721 smart contract calls this function on the recipient
  ///  after a `transfer`. This function MAY throw to revert and reject the
  ///  transfer. Return of other than the magic value MUST result in the
  ///  transaction being reverted.
  ///  Note: the contract address is always the message sender.
  /// @param _operator The address which called `safeTransferFrom` function
  /// @param _from The address which previously owned the token
  /// @param _tokenId The NFT identifier which is being transferred
  /// @param _data Additional data with no specified format
  /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  ///  unless throwing
  function onERC721Received(
    address _operator
  , address _from
  , uint256 _tokenId
  , bytes calldata _data
  ) external
    returns(bytes4);
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
 * @title: EIP-2981: NFT Royalty Standard
 * @author: Zach Burks, James Morgan, Blaine Malone, James Seibel
 * @notice the ERC-165 identifier for this interface is 0x2a55205a.
 * @custom:source https://eips.ethereum.org/EIPS/eip-2981
 * @custom:change-log MIT -> Apache-2.0
 *
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

interface IERC2981 is IERC165 {

  /// ERC165 bytes to add to interface array - set in parent contract
  /// implementing this standard

  /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  /// _registerInterface(_INTERFACE_ID_ERC2981);

  /// @notice Called with the sale price to determine how much royalty
  ///         is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for _salePrice
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external
    view
    returns (
      address receiver,
      uint256 royaltyAmount
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
 * @title: EIP-165: Standard Interface Detection
 * @author: Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 * @notice Creates a standard method to publish and detect what interfaces a smart contract implements.
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
 * @title: ERC-1155 Multi Token Standard, Token Receiver
 * @author: Witek Radomski, Andrew Cooke, Philippe Castonguay, James Therien, Eric Binet, Ronan Sandford
 * @notice See https://eips.ethereum.org/EIPS/eip-1155
 * @custom:note The ERC-165 identifier for this interface is 0x4e2312e0.
 * @custom:change-log MIT -> Apache-2.0
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

interface IERC1155TokenReceiver is IERC165 {

  /**
   @notice Handle the receipt of a single ERC1155 token type.
   @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract,
        at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return 
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61)
        if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the
        transaction being reverted by the caller.
   @param _operator  The address which initiated the transfer (i.e. msg.sender)
   @param _from      The address which previously owned the token
   @param _id        The ID of the token being transferred
   @param _value     The amount of tokens being transferred
   @param _data      Additional data with no specified format
   @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
  */
  function onERC1155Received(
    address _operator
  , address _from
  , uint256 _id
  , uint256 _value
  , bytes calldata _data
  ) external
    returns(bytes4);

  /**
   @notice Handle the receipt of multiple ERC1155 token types.
   @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract,
        at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return 
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81)
        if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the
        transaction being reverted by the caller.
   @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
   @param _from      The address which previously owned the token
   @param _ids       An array containing ids of each token being transferred 
                     (order and length must match _values array)
   @param _values    An array containing amounts of each token being transferred 
                     (order and length must match _ids array)
   @param _data      Additional data with no specified format
   @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
  */
  function onERC1155BatchReceived(
    address _operator
  , address _from
  , uint256[] calldata _ids
  , uint256[] calldata _values
  , bytes calldata _data
  ) external
    returns(bytes4);       
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
 * @title: ERC-1155 Multi Token Standard, Metadata URI
 * @author: Witek Radomski, Andrew Cooke, Philippe Castonguay, James Therien, Eric Binet, Ronan Sandford
 * @notice See https://eips.ethereum.org/EIPS/eip-1155
 * @custom:note The ERC-165 identifier for this interface is 0x0e89341c.
 * @custom:change-log MIT -> Apache-2.0
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

interface IERC1155MetadataURI is IERC165 {

  /**
   @notice A distinct Uniform Resource Identifier (URI) for a given token.
   @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
   @return URI string
  */
  function uri(
    uint256 _id
  ) external
    view
    returns (string memory);
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
 * @title: ERC-1155 Multi Token Standard
 * @author: Witek Radomski, Andrew Cooke, Philippe Castonguay, James Therien, Eric Binet, Ronan Sandford
 * @notice See https://eips.ethereum.org/EIPS/eip-1155
 * @custom:note The ERC-165 identifier for this interface is 0xd9b67a26.
 * @custom:change-log MIT -> Apache-2.0
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

interface IERC1155 is IERC165 {
  /**
   @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred,
        including zero value transfers as well as minting or burning
        (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is
        approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased
        by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
  */
  event TransferSingle(
    address indexed _operator
  , address indexed _from
  , address indexed _to
  , uint256 _id
  , uint256 _value);

  /**
   @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred,
        including zero value transfers as well as minting or burning 
        (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved 
        to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of
        tokens specified in _ids) the holder balance is decreased by and match what the recipient
        balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
  */
  event TransferBatch(
    address indexed _operator
  , address indexed _from
  , address indexed _to
  , uint256[] _ids
  , uint256[] _values);

  /**
   @dev MUST emit when approval for a second party/operator address to manage all tokens for an
        owner address is enabled or disabled (absence of an event assumes disabled).        
  */
  event ApprovalForAll(
    address indexed _owner
  , address indexed _operator
  , bool _approved);

  /**
   @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
  */
  event URI(
    string _value
  , uint256 indexed _id);

  /**
   @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address
           specified (with safety call).
   @dev Caller must be approved to manage the tokens being transferred out of the `_from` account
        (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change
        (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract
        (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately
        (see "Safe Transfer Rules" section of the standard).        
   @param _from    Source address
   @param _to      Target address
   @param _id      ID of the token type
   @param _value   Transfer amount
   @param _data    Additional data with no specified format, MUST be sent unaltered in call to
                   `onERC1155Received` on `_to`
  */
  function safeTransferFrom(
    address _from
  , address _to
  , uint256 _id
  , uint256 _value
  , bytes calldata _data
  ) external;

  /**
   @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address
           specified (with safety call).
   @dev Caller must be approved to manage the tokens being transferred out of the `_from` account
        (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than
        the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are
        reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays
        (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check
        if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant
        `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately
        (see "Safe Transfer Rules" section of the standard).                      
   @param _from    Source address
   @param _to      Target address
   @param _ids     IDs of each token type (order and length must match _values array)
   @param _values  Transfer amounts per token type (order and length must match _ids array)
   @param _data    Additional data with no specified format, MUST be sent unaltered in call to the
                   `ERC1155TokenReceiver` hook(s) on `_to`
  */
  function safeBatchTransferFrom(
    address _from
  , address _to
  , uint256[] calldata _ids
  , uint256[] calldata _values
  , bytes calldata _data
  ) external;

  /**
   @notice Get the balance of an account's tokens.
   @param _owner  The address of the token holder
   @param _id     ID of the token
   @return        The _owner's balance of the token type requested
  */
  function balanceOf(
    address _owner
  , uint256 _id
  ) external
    view
    returns (uint256);

  /**
   @notice Get the balance of multiple account/token pairs
   @param _owners The addresses of the token holders
   @param _ids    ID of the tokens
   @return The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
  */
  function balanceOfBatch(
    address[] calldata _owners
  , uint256[] calldata _ids
  ) external
    view
    returns (uint256[] memory);

  /**
   @notice Enable or disable approval for a third party ("operator") to manage all of the caller's
           tokens.
   @dev MUST emit the ApprovalForAll event on success.
   @param _operator  Address to add to the set of authorized operators
   @param _approved  True if the operator is approved, false to revoke approval
  */
  function setApprovalForAll(
    address _operator
  , bool _approved
  ) external;

  /**
   @notice Queries the approval status of an operator for a given owner.
   @param _owner     The owner of the tokens
   @param _operator  Address of authorized operator
   @return           True if the operator is approved, false if not
  */
  function isApprovedForAll(
    address _owner
  , address _operator
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
 * @title: [EIP1155] Max-1155 Implementation, using EIP 1822
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice ERC1155/1822 Gen 2 Implementation with:
 *          Enhanced EIP173 - Ownership via roles
 *          EIP2981 - NFT Royalties
 *          LayerZero omnichain enabled
 * @custom:error-codes Max1155:1 => "Max1155: Mint to address(0)"
 * @custom:error-codes Max1155:2 => "Max1155: Burn from address(0)"
 * @custom:error-codes Max1155:3 => "Max1155: address(0) can not own tokens"
 * @custom:error-codes Max1155:4 => "Max1155: ids/amounts mismatch"
 * @custom:error-codes Max1155:5 => "Max1155: Not owner or approved for all"
 * @custom:error-codes Max1155:6 => "Max1155: Token id non-existant"
 * @custom:error-codes Max1155:7 => "Max1155: No tokens to minter"
 * @custom:error-codes Max1155:8 => "Max1155: catch reason.length == 0"
 * @custom:error-codes Max1155LZ:1 => "Max1155LZ: Not from set endpoint"
 * @custom:error-codes Max1155LZ:2 => "Max1155LZ: Not from trusted remote"
 * @custom:error-codes Max1155LZ:3 => "Max1155LZ: Internals only for try/catch"
 * @custom:error-codes Max1155LZ:4 => "Max1155LZ: Message not stored"
 * @custom:error-codes Max1155LZ:5 => "Max1155LZ: payload noes not match failed message payload"
 * @custom:error-codes Max1155LZ:6 => "Max1155LZ: trustedRemote not set for chainId"
 * @custom:error-codes Max1155LZ:7 => "Max1155LZ: msg.value below messageFee needed to traverse"
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

pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./modules/access/IRoles.sol";
import "./eip/1155/IERC1155.sol";
import "./eip/1155/IERC1155MetadataURI.sol";
import "./eip/1155/IERC1155TokenReceiver.sol";
import "./eip/721/IERC721TokenReceiver.sol";
import "./modules/2981/IERC2981Admin.sol";
import "./lz/ILayerZeroReceiver.sol";
import "./lz/ILayerZeroEndpoint.sol";
import "./lib/Arrays.sol";
import "./lib/Address.sol";
import "./lib/Strings.sol";
import "./lib/1155.sol";
import "./lib/Roles.sol";
import "./lib/2981c.sol";

abstract contract Max1155UUPS2981LZ is Initializable
                                     , IRoles
                                     , IERC1155
                                     , IERC1155MetadataURI
                                     , IERC1155TokenReceiver
                                     , IERC721TokenReceiver
                                     , IERC2981Admin
                                     , ILayerZeroReceiver {

  using Lib1155 for Lib1155.Token;
  using Roles for Roles.Role;
  using Lib2981c for Lib2981c.Royalties;
  using Strings for uint256;
  using Arrays for uint256;
  using Address for address;

  // The Structs...
  Lib1155.Token internal token1155;
  Roles.Role internal contractRoles;
  Lib2981c.Royalties internal royalties;

  // The rest (got to have a few)
  bytes4 constant internal DEVS = 0xca4b208b;
  bytes4 constant internal OWNERS = 0x8da5cb5b;
  bytes4 constant internal ADMIN = 0xf851a440;
  bytes4 constant internal MINTER = 0x07546172;
  address internal factory;

  /// @dev this is Unauthorized(), basically a catch all, zero description
  /// @notice 0x82b42900 bytes4 of this
  error Unauthorized();

  /// @dev this is MaxSplaining(), giving you a reason, aka require(param, "reason")
  /// @param reason: Use the "Contract name: error"
  /// @notice 0x0661b792 bytes4 of this
  error MaxSplaining(
    string reason
  );

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
  uint256 internal gasForDestinationLzReceiveBase;
  uint256 internal gasForDestinationLzReceiveIncrement;

  event TrustedRemoteSet(uint16 _chainId, bytes _trustedRemote);
  event EndpointSet(address indexed _endpoint);
  event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

  ///////////////////////
  /// MAX-1155: Modifiers
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

  modifier onlyMinter() {
    if (contractRoles.has(MINTER, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  /////////////////////////////////////////////////////
  /// MAX-1155: Internals - init, hooks, mint, and burn
  /////////////////////////////////////////////////////

  function __Max1155_init(
    string memory _name
  , string memory _uri
  , address _admin
  , address _dev
  , address _owner
  ) internal
    onlyInitializing() {
    token1155.setName(_name);
    token1155.setURI(_uri);
    contractRoles.add(ADMIN, _admin);
    contractRoles.setAdmin(_admin);
    contractRoles.add(DEVS, _dev);
    contractRoles.setDeveloper(_dev);
    contractRoles.add(OWNERS, _owner);
    contractRoles.setOwner(_owner);
  }

  function _addMinterRole(
    address operator
  ) internal {
    contractRoles.add(MINTER, operator);
  }

  function _beforeHook1155(
    address operator
  , address from
  , address to
  , uint256[] memory ids
  , uint256[] memory amounts
  , bytes memory data
  ) internal {
    // the prior checks should have mismatch completed
    // minting only... address(0) => from
    uint256 len = ids.length;
    if (from == address(0)) {
      for (uint256 x = 0; x < len;) {
        token1155.upSupply(ids[x], amounts[x]);
        unchecked { ++x; }
      }
    }
    // burning only from => address(0)
    if (to == address(0)) {
      for (uint256 x = 0; x < len;) {
        token1155.downSupply(ids[x], amounts[x]);
        unchecked { ++x; }
      }
    }
  }

  function _safeHook1155(
    address operator
  , address from
  , address to
  , uint256 id
  , uint256 amount
  , bytes memory data
  ) internal
    returns (bool) {
    if (to.isContract()) {
      try IERC1155TokenReceiver(to).onERC1155Received(operator, from, id, amount, data)
        returns (bytes4 retval) {
        return retval == IERC1155TokenReceiver.onERC1155Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert MaxSplaining({
            reason: "Max1155:8"
          });
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      } 
    } else {
      return true;
    }
  }

  function _safeHook1155Batch(
    address operator
  , address from
  , address to
  , uint256[] memory id
  , uint256[] memory amount
  , bytes memory data
  ) internal
    returns (bool) {
    if (to.isContract()) {
      try IERC1155TokenReceiver(to).onERC1155BatchReceived(operator, from, id, amount, data)
        returns (bytes4 retval) {
        return retval == IERC1155TokenReceiver.onERC1155BatchReceived.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert MaxSplaining({
            reason: "Max1155:8"
          });
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      } 
    } else {
      return true;
    }
  }

  function _mint(
    address _to
  , uint256 _id
  , uint256 _amount
  , bytes memory _data
  ) internal {
    if (_to == address(0)) {
      revert MaxSplaining({
        reason: "Max1155:1"
      });
    }
    address sender = msg.sender;
    _beforeHook1155(sender, address(0), _to, _id.toArray(), _amount.toArray(), _data);
    token1155.mint(_to, _id, _amount);
    _safeHook1155(sender, address(0), _to, _id, _amount, _data);
    emit TransferSingle(sender, address(0), _to, _id, _amount);
  }

  function _mintBatch(
    address _to
  , uint256[] memory _ids
  , uint256[] memory _amounts
  , bytes memory _data
  ) internal {
    if (_to == address(0)) {
      revert MaxSplaining({
        reason: "Max1155:1"
      });
    }
    uint256 len = _ids.length;
    if (len != _amounts.length) {
      revert MaxSplaining({
        reason: "Max1155:4"
      });
    }
    address sender = msg.sender;
    _beforeHook1155(sender, address(0), _to, _ids, _amounts, _data);
    for (uint x = 0; x < len;) {
      token1155.mint(_to, _ids[x], _amounts[x]);
      unchecked { ++x; }
    }
    _safeHook1155Batch(sender, address(0), _to, _ids, _amounts, _data);
    emit TransferBatch(sender, address(0), _to, _ids, _amounts);
  }

  function _burn(
    address _from
  , uint256 _id
  , uint256 _amount
  , bytes memory _data
  ) internal {
    if (_from == address(0)) {
      revert MaxSplaining({
        reason: "Max1155:2"
      });
    }
    address sender = msg.sender;
    _beforeHook1155(sender, _from, address(0), _id.toArray(), _amount.toArray(), _data);
    token1155.burn(_from, _id, _amount);
    _safeHook1155(sender, _from, address(0), _id, _amount, _data);
    emit TransferSingle(sender, _from, address(0), _id, _amount);
  }

  function _burnBatch(
    address _from
  , uint256[] memory _ids
  , uint256[] memory _amounts
  , bytes memory _data
  ) internal {
    if (_from == address(0)) {
      revert MaxSplaining({
        reason: "Max1155:2"
      });
    }
    uint256 len = _ids.length;
    if (len != _amounts.length) {
      revert MaxSplaining({
        reason: "Max1155:4"
      });
    }
    address sender = msg.sender;
    _beforeHook1155(sender, _from, address(0), _ids, _amounts, _data);
    for (uint x = 0; x < len;) {
      token1155.burn(_from, _ids[x], _amounts[x]);
      unchecked { ++x; }
    }
    _safeHook1155Batch(sender, _from, address(0), _ids, _amounts, _data);
    emit TransferBatch(sender, _from, address(0), _ids, _amounts);
  }

  function name() 
    external
    view
    returns (string memory) {
    return token1155.getName();
  }

  //////////////////////////////////
  /// ERC-1155 Multi Token Standard
  //////////////////////////////////

  /**
   @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address
           specified (with safety call).
   @dev Caller must be approved to manage the tokens being transferred out of the `_from` account
        (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change
        (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract
        (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately
        (see "Safe Transfer Rules" section of the standard).
   @param _from    Source address
   @param _to      Target address
   @param _id      ID of the token type
   @param _value   Transfer amount
   @param _data    Additional data with no specified format, MUST be sent unaltered in call to
                   `onERC1155Received` on `_to`
  */
  function safeTransferFrom(
    address _from
  , address _to
  , uint256 _id
  , uint256 _value
  , bytes calldata _data
  ) external
    virtual
    override {
    if (_from != msg.sender && !this.isApprovedForAll(_from, msg.sender)) {
      revert MaxSplaining({
        reason: "Max1155:5"
      });
    }
    token1155.doTransferFrom(_from, _to, _id, _value);
    _safeHook1155(msg.sender, _from, _to, _id, _value, _data);
    emit TransferSingle(msg.sender, _from, _to, _id, _value);
  }

  /**
   @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address
           specified (with safety call).
   @dev Caller must be approved to manage the tokens being transferred out of the `_from` account
        (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than
        the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are
        reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays
        (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check
        if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant
        `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately
        (see "Safe Transfer Rules" section of the standard).
   @param _from    Source address
   @param _to      Target address
   @param _ids     IDs of each token type (order and length must match _values array)
   @param _values  Transfer amounts per token type (order and length must match _ids array)
   @param _data    Additional data with no specified format, MUST be sent unaltered in call to the
                   `ERC1155TokenReceiver` hook(s) on `_to`
  */
  function safeBatchTransferFrom(
    address _from
  , address _to
  , uint256[] calldata _ids
  , uint256[] calldata _values
  , bytes calldata _data
  ) external
    virtual
    override {
    if (_from != msg.sender && !this.isApprovedForAll(_from, msg.sender)) {
      revert MaxSplaining({
        reason: "Max1155:5"
      });
    }
    uint256 len = _ids.length;
    if (len != _values.length) {
      revert MaxSplaining({
        reason: "Max1155:4"
      });
    }
    for (uint256 x = 0; x < len;) {
      token1155.doTransferFrom(_from, _to, _ids[x], _values[x]);
      unchecked { ++x; }
    }
    _safeHook1155Batch(msg.sender, _from, _to, _ids, _values, _data);
    emit TransferBatch(msg.sender, _from, _to, _ids, _values);
  }

  /**
   @notice Get the balance of an account's tokens.
   @param _owner  The address of the token holder
   @param _id     ID of the token
   @return        The _owner's balance of the token type requested
  */
  function balanceOf(
    address _owner
  , uint256 _id
  ) external
    view
    virtual
    override
    returns (uint256) {
    if (_owner == address(0)) {
      revert MaxSplaining({
        reason: "Max1155:3"
      });
    }
    return token1155.getBalanceOf(_owner, _id);
  }

  /**
   @notice Get the balance of multiple account/token pairs
   @param _owners The addresses of the token holders
   @param _ids    ID of the tokens
   @return The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
  */
  function balanceOfBatch(
    address[] calldata _owners
  , uint256[] calldata _ids
  ) external
    view
    virtual
    override
    returns (uint256[] memory) {
    if (_owners.length != _ids.length) {
      revert MaxSplaining({
        reason: "Max1155:4"
      });
    }
    uint256[] memory _balances = new uint256[](_owners.length);

    for (uint256 x = 0; x < _owners.length;) {
      _balances[x] = this.balanceOf(_owners[x], _ids[x]);
      unchecked { ++x; }
    }

    return _balances;
  }

  /**
   @notice Enable or disable approval for a third party ("operator") to manage all of the caller's
           tokens.
   @dev MUST emit the ApprovalForAll event on success.
   @param _operator  Address to add to the set of authorized operators
   @param _approved  True if the operator is approved, false to revoke approval
  */
  function setApprovalForAll(
    address _operator
  , bool _approved
  ) external
    virtual
    override {
    token1155.setApprovalForAll(msg.sender, _operator, _approved);
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   @notice Queries the approval status of an operator for a given owner.
   @param _owner     The owner of the tokens
   @param _operator  Address of authorized operator
   @return           True if the operator is approved, false if not
  */
  function isApprovedForAll(
    address _owner
  , address _operator
  ) external
    view
    virtual
    override
    returns (bool) {
    return token1155.isApprovedForAll(_owner, _operator);
  }

  //////////////////////////////////////////////////
  /// ERC-1155 Multi Token Standard, Token Receiver
  //////////////////////////////////////////////////

  /**
   @notice Handle the receipt of a single ERC1155 token type.
   @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract,
        at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61)
        if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the
        transaction being reverted by the caller.
   @param _operator  The address which initiated the transfer (i.e. msg.sender)
   @param _from      The address which previously owned the token
   @param _id        The ID of the token being transferred
   @param _value     The amount of tokens being transferred
   @param _data      Additional data with no specified format
   @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
  */
  function onERC1155Received(
    address _operator
  , address _from
  , uint256 _id
  , uint256 _value
  , bytes calldata _data
  ) external
    virtual
    override
    returns(bytes4) {
      revert MaxSplaining({
        reason: "Max1155:7"
      });
    }

  /**
   @notice Handle the receipt of multiple ERC1155 token types.
   @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract,
        at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81)
        if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the
        transaction being reverted by the caller.
   @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
   @param _from      The address which previously owned the token
   @param _ids       An array containing ids of each token being transferred
                     (order and length must match _values array)
   @param _values    An array containing amounts of each token being transferred
                     (order and length must match _ids array)
   @param _data      Additional data with no specified format
   @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
  */
  function onERC1155BatchReceived(
    address _operator
  , address _from
  , uint256[] calldata _ids
  , uint256[] calldata _values
  , bytes calldata _data
  ) external
    virtual
    override
    returns(bytes4) {
      revert MaxSplaining({
        reason: "Max1155:7"
      });
    }

  ////////////////////////////////////////////////////////
  /// ERC-721 Non-Fungible Token Standard, Token Receiver
  ////////////////////////////////////////////////////////

  /// @notice Handle the receipt of an NFT
  /// @notice The ERC721 smart contract calls this function on the recipient
  ///  after a `transfer`. This function MAY throw to revert and reject the
  ///  transfer. Return of other than the magic value MUST result in the
  ///  transaction being reverted.
  ///  Note: the contract address is always the message sender.
  /// @param _operator The address which called `safeTransferFrom` function
  /// @param _from The address which previously owned the token
  /// @param _tokenId The NFT identifier which is being transferred
  /// @param _data Additional data with no specified format
  /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  ///  unless throwing
  function onERC721Received(
    address _operator
  , address _from
  , uint256 _tokenId
  , bytes calldata _data
  ) external
    virtual
    override
    returns(bytes4) {
      revert MaxSplaining({
        reason: "Max1155:7"
      });
    }

  ////////////////////////////////////////////////
  /// ERC-1155 Multi Token Standard, Metadata URI
  ////////////////////////////////////////////////

  /**
   @notice A distinct Uniform Resource Identifier (URI) for a given token.
   @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
   @return URI string
  */
  function uri(
    uint256 _id
  ) external
    view
    virtual
    override
    returns (string memory) {
    if (!token1155.tokenExists(_id)) {
      revert MaxSplaining({
        reason: "Max1155:6"
      });
    } else {
      string memory base = token1155.uri;
      return bytes(base).length > 0 ? string(abi.encodePacked(base, _id.toString())) : _id.toString();
    }
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
        reason: "Max1155LZ:1"
      });
    }

    if (
      _srcAddress.length != trustedRemoteLookup[_srcChainId].length ||
      keccak256(_srcAddress) != keccak256(trustedRemoteLookup[_srcChainId])
    ) {
      revert MaxSplaining({
        reason: "Max1155LZ:2"
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
        reason: "Max1155LZ:3"
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
    , _payload
    , _refundAddress
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
        reason: "Max1155LZ:4"
      });
    }
    if (
      _payload.length != failedMsg.payloadLength ||
      keccak256(_payload) != failedMsg.payloadHash
    ) {
      revert MaxSplaining({
        reason: "Max1155LZ:5"
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
    external
    view
    virtual
    returns(address) {
    return contractRoles.getOwner();
  }
	
  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract    
  function transferOwnership(
    address _newOwner
  ) external
    virtual
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
    virtual
    onlyRole(OWNERS) {
    contractRoles.setOwner(address(0));
    contractRoles.remove(OWNERS, msg.sender);
  }

  //////////////////////////////////////////////
  /// [Not an EIP]: Contract Developer Standard
  //////////////////////////////////////////////

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @return Developer of contract
  function developer()
    external
    view
    virtual
    returns (address) {
    return contractRoles.getDeveloper();
  }

  /// @dev This renounces your role as onlyDev()
  function renounceDeveloper()
    external
    virtual
    onlyRole(DEVS) {
    contractRoles.setDeveloper(address(0));
    contractRoles.remove(DEVS, msg.sender);
  }

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @param newDeveloper: addres of new pending Developer role
  function transferDeveloper(
    address newDeveloper
  ) external
    virtual
    onlyRole(DEVS) {
    contractRoles.add(DEVS, newDeveloper);
    contractRoles.setDeveloper(newDeveloper);
    contractRoles.remove(DEVS, msg.sender);
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
    virtual
    override
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
    virtual
    override
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
    virtual
    override
    onlyRole(role) {
    contractRoles.add(role, account);
  }

  /// @dev Revokes `role` from `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to revoke role from
  function revokeRole(
    bytes4 role
  , address account
  ) external
    virtual
    override
    onlyRole(role) {
    contractRoles.remove(role, account);
  }

  /// @dev Renounces `role` from `account`
  /// @param role: Bytes4 of a role
  function renounceRole(
    bytes4 role
  ) external
    virtual
    override
    onlyRole(role) {
    contractRoles.remove(role, msg.sender);
  }

  ///////////////////////////////////
  /// EIP-2981: NFT Royalty Standard
  ///////////////////////////////////

  /// @notice Called with the sale price to determine how much royalty
  ///         is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for _salePrice
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external
    view
    virtual
    override
    returns (
      address receiver,
      uint256 royaltyAmount
    ) {
    (receiver, royaltyAmount) = royalties.royaltyInfo(_tokenId,_salePrice);
  }

  ////////////////////////////////////////////////////
  /// EIP-2981: NFT Royalty Standard, admin extension
  /// @dev Using the collection standard
  ////////////////////////////////////////////////////

  /// @dev function (state storage) sets the royalty data for a token
  /// @param tokenId uint256 for the token
  /// @param receiver address for the royalty reciever for token
  /// @param permille uint16 for the permille of royalties 20 -> 2.0%
  function setRoyalties(
    uint256 tokenId
  , address receiver
  , uint16 permille
  ) external
    virtual
    override {
    revert Unauthorized();
  }

  /// @dev function (state storage) revokes the royalty data for a token
  /// @param tokenId uint256 for the token
  function revokeRoyalties(
    uint256 tokenId
  ) external
    virtual
    override {
    revert Unauthorized();
  }

  /// @dev function (state storage) sets the royalty data for a collection
  /// @param receiver address for the royalty reciever for token
  /// @param permille uint16 for the permille of royalties 20 -> 2.0%
  function setRoyalties(
    address receiver
  , uint16 permille
  ) external
    virtual
    onlyOwner()
    override {
    royalties.setRoyalties(receiver, permille);
  }

  /// @dev function (state storage) revokes the royalty data for a collection
  function revokeRoyalties()
    external
    virtual
    onlyOwner()
    override {
    royalties.revokeRoyalties();
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
      interfaceID == type(IERC165).interfaceId  ||
      interfaceID == type(IERC1155).interfaceId  ||
      interfaceID == type(IERC1155MetadataURI).interfaceId  ||
      interfaceID == type(IERC2981).interfaceId  ||
      interfaceID == type(ILayerZeroReceiver).interfaceId
    );
  }

  ////////////////////////////
  /// The Gap for EIP 1822...
  ////////////////////////////

  // @dev set this to max (50) minus storage slots
  uint256[37] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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