// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interface/IEvent.sol";
contract Event is IEvent{
    address private _controller;
    address private _usdb;
    address private _tuna;
    address private _pledgedMining;
    address private _bora;
    address private _owner;
    constructor(){
            _owner = msg.sender;
        }
        modifier onlyController(){
            require(msg.sender == _controller, "Event: you are not controller.");
            _;
        }
        modifier onlyUsdb(){
            require(msg.sender == _usdb, "Event: you are not usdb.");
            _;
        }
        modifier onlyTuna(){
            require(msg.sender == _tuna, "Event: you are not tuna.");
            _;
        }
        modifier onlyPledgedMining(){
            require(msg.sender == _pledgedMining, "Event: you are not pledgedMining.");
            _;
        }
        modifier onlyBora(){
            require(msg.sender == _bora, "Event: you are not bora.");
            _;
        }
        function Controller_setPledgedToken(address tokenAddress, bool isOpen, uint256 rate) external onlyController {
            emit Controller_setPledgedTokenEvent(tokenAddress, isOpen, rate);
        }
        function Controller_claim(uint256 id, address player, uint256 usdbAmount, uint256 usdbBalance, address usdbAddress) external onlyController{
            emit Controller_claimEvent(id, player, usdbAmount, usdbBalance, usdbAddress);
        }
        function Controller_airDrop(uint256 id, address player, uint256 usdbAmount, uint256 usdbBalance, address usdbAddress) external onlyController {
            emit Controller_airDropEvent(id, player, usdbAmount, usdbBalance, usdbAddress);
        }
        function Controller_stake(address player, address tokenAddress, uint256 tokenAmount, uint256 ustAmount, uint256 totalUstAmount, address usdbAddress) external onlyController{
            emit Controller_stakeEvent(player, tokenAddress, tokenAmount, ustAmount, totalUstAmount, usdbAddress);
        }
        function Controller_unStake(address player, uint256 totalUstAmount, address usdbAddress) external onlyController {
            emit Controller_unStakeEvent(player, totalUstAmount, usdbAddress);
        }
        function USDB_unStake(address owner, address tokenAddress, uint256 tokenAmount, address usdbAddress) external onlyUsdb {
            emit USDB_unStakeEvent(owner, tokenAddress, tokenAmount, usdbAddress);
        }
        function Tuna_claim(address player, uint256 burnAmount, uint256 claimVolAmount, address tunaAddress) external onlyTuna {
            emit Tuna_claimEvent(player, burnAmount, claimVolAmount, tunaAddress);
        }
        function Tuna_claimBnb(address player, uint256 amount, address tunaAddress) external onlyTuna {
            emit Tuna_claimBnbEvent(player, amount, tunaAddress);
        }
        function Tuna_burnThroughUpdate(address owner, uint256 amount, address tunaAddress) external onlyTuna {
            emit Tuna_burnThroughUpdateEvent(owner, amount, tunaAddress);
        }
        function PledgedMining_stake(address owner, uint256 amount, address tunaAddress) external onlyPledgedMining {
            emit PledgedMining_stakeEvent(owner, amount, tunaAddress);
        }
        function PledgedMining_stakeByTunaClaim(address owner, uint256 amount, address tunaAddress) external onlyPledgedMining{
            emit PledgedMining_stakeByTunaClaimEvent(owner, amount, tunaAddress);
        }
        function PledgedMining_unStake(address owner, uint256 stakeAmount, address tunaAddress) external onlyPledgedMining{
            emit PledgedMining_unStakeEvent(owner, stakeAmount, tunaAddress);
        }
        function PledgedMining_claim(address owner, uint256 claimAmount, address tunaAddress) external onlyPledgedMining {
            emit PledgedMining_claimEvent(owner, claimAmount, tunaAddress);
        }
        function Bora_mint(address player, uint256 tokenId) external onlyBora {
            emit Bora_mintEvent(player, tokenId);
        }
        function Bora_updateLevel(address owner, uint256 tokenId, uint256 levels, uint256 NFTLevel, uint256 tunaAmount, uint256 feature) external onlyBora {
            emit Bora_updateLevelEvent(owner, tokenId, levels, NFTLevel, tunaAmount, feature);
        }
        function Bora_transferFrom(address from, address to,uint256 tokenId) external {
            emit Bora_transferFromEvent(from, to, tokenId);
        }
        function setCallers(
        address controller,
        address usdb,
        address tuna,
        address pledgedMining,
        address bora) public {
            require(msg.sender == _owner, "Event: you are not owner");
            _controller = controller;
            _usdb = usdb;
            _tuna = tuna;
            _pledgedMining = pledgedMining;
            _bora = bora;
        }
        function getController() public view returns(address){
            return _controller;
        }
        
        function getUsdb() public view returns(address){
            return _usdb;
        }
        function getTuna() public view returns(address){
            return _tuna;
        }
        function getPledgedMining() public view returns(address){
            return _pledgedMining;
        }
        function getBora() public view returns(address){
            return _bora;
        }
        function getOwner() public view returns(address){
            return _owner;
        }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IEvent {
        event Controller_setPledgedTokenEvent(address tokenAddress, bool isOpen, uint256 rate);
        event Controller_claimEvent(uint256 id, address player, uint256 usdbAmount, uint256 usdbBalance, address usdbAddress);
        event Controller_airDropEvent(uint256 id, address player, uint256 usdbAmount, uint256 usdbBalance, address usdbAddress);
        event Controller_stakeEvent(address player, address tokenAddress, uint256 tokenAmount, uint256 ustAmount, uint256 totalUstAmount, address usdbAddress);
        event Controller_unStakeEvent(address player, uint256 totalUstAmount, address usdbAddress);
        event USDB_unStakeEvent(address owner, address tokenAddress, uint256 tokenAmount, address usdbAddress);
        event Tuna_claimEvent(address player, uint256 burnAmount, uint256 claimVolAmount, address tunaAddress);
        event Tuna_claimBnbEvent(address player, uint256 amount, address tunaAddress);
        event Tuna_burnThroughUpdateEvent(address owner, uint256 amount, address tunaAddress);
        event PledgedMining_stakeEvent(address owner, uint256 amount, address tunaAddress);
        event PledgedMining_stakeByTunaClaimEvent(address owner, uint256 amount, address tunaAddress);
        event PledgedMining_unStakeEvent(address owner, uint256 stakeAmount, address tunaAddress);
        event PledgedMining_claimEvent(address owner, uint256 claimAmount, address tunaAddress);
        event Bora_mintEvent(address player, uint256 tokenId);
        event Bora_updateLevelEvent(address owner, uint256 tokenId, uint256 levels, uint256 NFTLevel, uint256 tunaAmount, uint256 feature);
        event Bora_transferFromEvent(address from, address to, uint256 tokenId);
        function Controller_setPledgedToken(address tokenAddress, bool isOpen, uint256 rate) external;
        function Controller_claim(uint256 id, address player, uint256 usdbAmount, uint256 usdbBalance, address usdbAddress) external;
        function Controller_airDrop(uint256 id, address player, uint256 usdbAmount, uint256 usdbBalance, address usdbAddress) external;
        function Controller_stake(address player, address tokenAddress, uint256 tokenAmount, uint256 ustAmount, uint256 totalUstAmount, address usdbAddress) external;
        function Controller_unStake(address player, uint256 totalUstAmount, address usdbAddress) external;
        function USDB_unStake(address owner, address tokenAddress, uint256 tokenAmount, address usdbAddress) external;
        function Tuna_claim(address player, uint256 burnAmount, uint256 claimVolAmount, address tunaAddress) external;
        function Tuna_claimBnb(address player, uint256 amount, address tunaAddress) external;
        function Tuna_burnThroughUpdate(address owner, uint256 amount, address tunaAddress) external;
        function PledgedMining_stake(address owner, uint256 amount, address tunaAddress) external;
        function PledgedMining_stakeByTunaClaim(address owner, uint256 amount, address tunaAddress) external;
        function PledgedMining_unStake(address owner, uint256 stakeAmount, address tunaAddress) external;
        function PledgedMining_claim(address owner, uint256 claimAmount, address tunaAddress) external;
        function Bora_mint(address player, uint256 tokenId) external;
        function Bora_updateLevel(address owner, uint256 tokenId, uint256 levels, uint256 NFTLevel, uint256 tunaAmount, uint256 feature) external;
        function Bora_transferFrom(address from, address to,uint256 tokenId) external;
}