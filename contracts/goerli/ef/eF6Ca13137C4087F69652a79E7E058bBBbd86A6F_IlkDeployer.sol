// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SpellLib.sol";

interface SpotterLike {
    function poke(bytes32) external;
}
interface DSValueAbstract {
    function init() external;
    function poke(bytes32 wut) external;
}
interface IlkRegistryAbstract {
    function add(address) external;
}
interface IProxy {
    function changeAdmin(address newAdmin) external returns(bool);
    function upgrad(address newLogic) external returns(bool);
}
interface DSTokenAbstract {
    function decimals() external view returns (uint256);
}
interface DssSpellAbstract {
    function schedule() external;
    function cast() external;
}
interface GemJoinAbstract {
    function init(address vat_, bytes32 ilk_, address gem_) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
}
interface PauseLike {
    function delay() external returns (uint);
    function proxy() external view returns (address);
    function exec(address, bytes32, bytes memory, uint256) external;
    function plot(address, bytes32, bytes memory, uint256) external;
}
interface FlipAbstract {
    function init(address vat_, address cat_, bytes32 ilk_) external;
    function rely(address usr) external;
    function vat() external view returns (address);
    function cat() external view returns (address);
    function ilk() external view returns (bytes32);
}
interface ConfigLike {
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint) external;
    function rely(address) external;
}

contract IlkDeployer {
    // decimals & precision
    uint256 constant public WAD = 10 ** 18;
    uint256 constant public RAY = 10 ** 27;
    uint256 constant public RAD = 10 ** 45;
    function deploy(bytes32 ilk_, address[11] calldata addrs, uint[9] calldata vals) external {
        // addrs[0] = vat
        // addrs[1] = cat
        // addrs[2] = jug
        // addrs[3] = spotter
        // addrs[4] = end
        // addrs[5] = join
        // addrs[6] = pip
        // addrs[7] = flip
        // addrs[8] = IlkRegistry
        // addrs[9] = gem
        // addrs[10] = FLIPPER_MOM

        // vals[0] = line
        // vals[1] = mat
        // vals[2] = duty
        // vals[3] = chop
        // vals[4] = dunk
        // vals[5] = dust
        // vals[6] = beg
        // vals[7] = ttl
        // vals[8] = tau
        require(GemJoinAbstract(addrs[5]).vat() == addrs[0], "join-vat-not-match");
        require(GemJoinAbstract(addrs[5]).ilk() == ilk_, "join-ilk-not-match");
        require(GemJoinAbstract(addrs[5]).gem() == addrs[9], "join-gem-not-match");
        require(GemJoinAbstract(addrs[5]).dec() == DSTokenAbstract(addrs[9]).decimals(), "join-dec-not-match");
        require(FlipAbstract(addrs[7]).vat() == addrs[0], "flip-vat-not-match");
        require(FlipAbstract(addrs[7]).cat() == addrs[1], "flip-cat-not-match");
        require(FlipAbstract(addrs[7]).ilk() == ilk_, "flip-ilk-not-match");

        ConfigLike(addrs[3]).file(ilk_, "pip", address(addrs[6])); // vat.file(ilk_, "pip", pip);

        ConfigLike(addrs[1]).file(ilk_, "flip", addrs[7]); // cat.file(ilk_, "flip", flip);
        ConfigLike(addrs[0]).init(ilk_); // vat.init(ilk_);
        ConfigLike(addrs[2]).init(ilk_); // jug.init(ilk_);

        ConfigLike(addrs[0]).rely(addrs[5]); // vat.rely(join);
        ConfigLike(addrs[1]).rely(addrs[7]); // cat.rely(flip);
        ConfigLike(addrs[7]).rely(addrs[1]); // flip.rely(cat);
        ConfigLike(addrs[7]).rely(addrs[4]); // flip.rely(end);
        ConfigLike(addrs[7]).rely(addrs[10]); // flip.rely(FlipperMom);

        ConfigLike(addrs[0]).file(ilk_, "line", vals[0] * RAD); // vat.file(ilk_, "line", line);
        ConfigLike(addrs[0]).file(ilk_, "dust", vals[5] * RAD); // vat.file(ilk_, "dust", dust);
        ConfigLike(addrs[1]).file(ilk_, "dunk", vals[4] * RAD); // cat.file(ilk_, "dunk", dunk);
        ConfigLike(addrs[1]).file(ilk_, "chop", (100 + vals[3]) * WAD / 100); // cat.file(ilk_, "chop", chop);
        //ConfigLike(addrs[2]).file(ilk_, "duty", (100 + vals[2]) * RAY / 100); // jug.file(ilk_, "duty", duty);//1000000001547125957863212448
        ConfigLike(addrs[2]).file(ilk_, "duty", vals[2]); // jug.file(ilk_, "duty", duty);
        ConfigLike(addrs[7]).file("beg", (100 + vals[6]) * WAD / 100); // flip.file("beg", beg);
        ConfigLike(addrs[7]).file("ttl", vals[7]); // flip.file("ttl", ttl);
        ConfigLike(addrs[7]).file("tau", vals[8]); // flip.file("tau", tau);
        ConfigLike(addrs[3]).file(ilk_, "mat", vals[1] * RAY / 100); // spotter.file(ilk_, "mat", mat);

        // Update spot value in Vat
        SpotterLike(addrs[3]).poke(ilk_); // spotter.poke(ilk_);
        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(addrs[8]).add(addrs[5]);
    }
}

contract DssSpell {
    PauseLike       public pause;
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    string constant public description = "Spell Deploy";

    constructor(
        address _pause,
        address _action,
        bytes memory _sig
    ) {
        pause = PauseLike(_pause);
        sig = _sig;
        action = _action;
        bytes32 _tag;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = block.timestamp + 30 days;
    }

    function schedule() external {
        require(block.timestamp <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = block.timestamp + pause.delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() external {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

contract DssAddIlkSpell is Initializable,Ownable{
    address public executor;
    AddressMsg public addressMsg;
    ValueMsg public valueMsg;
    uint256 public num;
    mapping(uint256 => AddIlkSpellMsg) public addIlkSpellMsg;
    mapping(bytes32 => uint256) public addIlk;

    event UpdateExecutor(address _executor);
    event AddIlkSpell(uint256 _index, address _token, address _join, address _flip, address _pip, address _spell, bytes32 _ilk);
    event Schedules(uint256 _index);
    event Casts(uint256 _index);
    event Pokes(uint256 _index, address _pip, uint256 _val);

    struct AddIlkSpellMsg{
        bytes32    ilk;
        address    token;
        address    join;
        address    flip;
        address    pip;
        address    spell;
    }
  
    struct AddressMsg{
        address MCD_PAUSE;
        address MCD_VAT;
        address MCD_CAT;
        address MCD_JUG;
        address MCD_END;
        address MCD_SPOT;
        address FLIPPER_MOM;
        address ILK_REGISTRY;
        address ILK_DEPLOYER;
        address JOIN_IMPL;
        address FLIP_IMPL;
        address PIP_IMPL;
    }
    //goerli
    //JOIN_IMPL = 0x6c99291bD524fD12e5c2845802Ab772a70Af0F10
    //FLIP_IMPL = 0x75cb9268c803be4dBC4B7EbB54b6e53e82dd31Af
    //PIP_IMPL = 0x9c694F6B55257Ea9d3288fE9eaa2B927c7dF8166
  
    struct ValueMsg{
        uint256 line;
        uint256 dust;
        uint256 dunk;
        uint256 chop;
        uint256 duty;
        uint256 beg;
        uint256 ttl;
        uint256 tau;
        uint256 mat;
    }
    
    modifier onlyExecutor() {
        require(msg.sender == executor, "PledgeContract: caller is not the admin");
        _;
    }

    function init(
        address _executor,
        address[12] calldata addrs, 
        uint[9] calldata vals
    )  external 
       initializer
    {
        __Ownable_init_unchained();
        __DssAddIlkSpell_init_unchained(_executor, addrs, vals);
    }

    function __DssAddIlkSpell_init_unchained(
        address _executor,
        address[12] calldata addrs, 
        uint[9] calldata vals
    ) internal 
      initializer
    {
        executor = _executor;
        addressMsg.MCD_PAUSE = addrs[0];
        addressMsg.MCD_VAT = addrs[1];
        addressMsg.MCD_CAT = addrs[2];
        addressMsg.MCD_JUG = addrs[3];
        addressMsg.MCD_END = addrs[4];
        addressMsg.MCD_SPOT = addrs[5];
        addressMsg.FLIPPER_MOM = addrs[6];
        addressMsg.ILK_REGISTRY = addrs[7];
        addressMsg.ILK_DEPLOYER = addrs[8];//address(new IlkDeployer());
        addressMsg.JOIN_IMPL = addrs[9];
        addressMsg.FLIP_IMPL = addrs[10];
        addressMsg.PIP_IMPL = addrs[11];
        valueMsg.line = vals[0];
        valueMsg.dust = vals[1];
        valueMsg.dunk = vals[2];
        valueMsg.chop = vals[3];
        valueMsg.duty = vals[4];
        valueMsg.beg = vals[5];
        valueMsg.ttl = vals[6];
        valueMsg.tau = vals[7];
        valueMsg.mat = vals[8];        
    }
    
    function updateExecutor(address _executor) external onlyOwner{
        executor = _executor;
        emit UpdateExecutor(_executor);
    }
    

    function addIlkSpell(bytes32 _ilk, address _token, uint256 _price) onlyExecutor() external {
        _addIlkSpell(_ilk, _token, _price);
    }
           
    function schedules(uint256[] calldata _nums) external {
        for (uint256 i = 0; i< _nums.length; i++){
            AddIlkSpellMsg memory _addIlkSpellMsg = addIlkSpellMsg[_nums[i]];
            DssSpellAbstract(_addIlkSpellMsg.spell).schedule();
            emit Schedules(_nums[i]);
        }
    }
    
    function casts(uint256[] calldata _nums) external {
        for (uint256 i = 0; i< _nums.length; i++){
            AddIlkSpellMsg memory _addIlkSpellMsg = addIlkSpellMsg[_nums[i]];
            DssSpellAbstract(_addIlkSpellMsg.spell).cast();
            emit Casts(_nums[i]);
        }
    }
       
    function scheduleAndCast(uint256[] calldata _nums) external {
        AddIlkSpellMsg memory _addIlkSpellMsg;
        for (uint256 i = 0; i< _nums.length; i++){
            _addIlkSpellMsg = addIlkSpellMsg[_nums[i]];
            DssSpellAbstract(_addIlkSpellMsg.spell).schedule();
            DssSpellAbstract(_addIlkSpellMsg.spell).cast();
            emit Schedules(_nums[i]);
            emit Casts(_nums[i]);
        }
    }
   
    function addIlkSpell(bytes32[] calldata _ilks, address[] calldata _tokens, uint256[] calldata _prices) onlyExecutor() external {
        require(_ilks.length == _tokens.length && _tokens.length == _prices.length, "Parameter array length does not match");
        for (uint256 i = 0; i< _tokens.length; i++){
            _addIlkSpell(_ilks[i], _tokens[i], _prices[i]);
        }
    }
   
    function pokes(uint256[] calldata _nums, address[] calldata _pips, uint256[] calldata _vals) onlyOwner() external{ 
        require(_nums.length == _vals.length && _pips.length == _vals.length, "Parameter array length does not match");
        for (uint256 i = 0; i< _nums.length; i++){
            AddIlkSpellMsg memory _addIlkSpellMsg = addIlkSpellMsg[_nums[i]];
            require(_addIlkSpellMsg.pip == _pips[i], "pip address does not match");
            DSValueAbstract(_addIlkSpellMsg.pip).poke(bytes32(_vals[i]));
            SpotterLike(addressMsg.MCD_SPOT).poke(_addIlkSpellMsg.ilk);
            emit Pokes(_nums[i], _pips[i], _vals[i]);
        }
    }

    function updateProxyAdmin(address[] calldata _targetAddrs, address[] calldata _addrs) onlyOwner() external{
        require(_targetAddrs.length == _addrs.length, "Parameter array length does not match");
        for (uint256 i = 0; i< _targetAddrs.length; i++){
            IProxy proxy = IProxy(_targetAddrs[i]);
            proxy.changeAdmin(_addrs[i]);
        }
    }
      
    function updateProxyUpgrad(address[] calldata _targetAddrs, address[] calldata _addrs) onlyOwner() external{
        require(_targetAddrs.length == _addrs.length, "Parameter array length does not match");
        for (uint256 i = 0; i< _targetAddrs.length; i++){
            IProxy proxy = IProxy(_targetAddrs[i]);
            proxy.upgrad(_addrs[i]);
        }
    }
      
    function excContract(address[] calldata _targetAddrs, bytes[] calldata _datas) onlyOwner() external{
        require(_targetAddrs.length == _datas.length, "Parameter array length does not match");
        for (uint256 i = 0; i< _targetAddrs.length; i++){
            require(bytesToUint(_datas[i]) != 2401778032 && bytesToUint(_datas[i]) != 822583150, "Calls to methods of proxy contracts are not allowed");
            (bool result, ) = _targetAddrs[i].call(_datas[i]);
            require(result, "The method call failed");
        }
    }

    function _addIlkSpell(bytes32 _ilk, address _token, uint256 _price) internal {
        require(addIlk[_ilk] ==0, "spell-already-add");
        uint256 _num = ++num;
        addIlk[_ilk] = _num;
        AddIlkSpellMsg storage _addIlkSpellMsg = addIlkSpellMsg[_num];
        _addIlkSpellMsg.ilk = _ilk;
        _addIlkSpellMsg.token = _token;
        _addIlkSpellMsg.join = address(new JoinPorxy(addressMsg.JOIN_IMPL));
        _addIlkSpellMsg.flip = address(new FlipPorxy(addressMsg.FLIP_IMPL));
        _addIlkSpellMsg.pip = address(new DSValuePorxy(addressMsg.PIP_IMPL));
        FlipAbstract(_addIlkSpellMsg.flip).init(addressMsg.MCD_VAT, addressMsg.MCD_CAT, _ilk);
        FlipAbstract(_addIlkSpellMsg.flip).rely(PauseLike(addressMsg.MCD_PAUSE).proxy());
        GemJoinAbstract(_addIlkSpellMsg.join).init(addressMsg.MCD_VAT, _ilk, _token);
        DSValueAbstract(_addIlkSpellMsg.pip).init();
        DSValueAbstract(_addIlkSpellMsg.pip).poke(bytes32(_price));
        bytes memory sig = abi.encodeWithSignature("deploy(bytes32,address[11],uint256[9])", _ilk, 
                                [addressMsg.MCD_VAT, addressMsg.MCD_CAT, addressMsg.MCD_JUG, addressMsg.MCD_SPOT, addressMsg.MCD_END,
                                _addIlkSpellMsg.join, _addIlkSpellMsg.pip, _addIlkSpellMsg.flip, addressMsg.ILK_REGISTRY, _token, addressMsg.FLIPPER_MOM],
                                [valueMsg.line, valueMsg.mat, valueMsg.duty, valueMsg.chop, valueMsg.dunk, valueMsg.dust, valueMsg.beg, 
                                valueMsg.ttl, valueMsg.tau]);
        _addIlkSpellMsg.spell = address(new DssSpell(addressMsg.MCD_PAUSE, addressMsg.ILK_DEPLOYER, sig));
        emit AddIlkSpell(_num, _token, _addIlkSpellMsg.join, _addIlkSpellMsg.flip, _addIlkSpellMsg.pip, _addIlkSpellMsg.spell, _ilk);
    }
    
    function bytesToUint(bytes memory _data) internal pure returns (uint256){
        require(_data.length >= 4, "Insufficient byte length");
        uint256 number;
        for(uint i= 0; i<4; i++){
            number = number + uint8(_data[i])*(2**(8*(4-(i+1))));
        }
        return  number;
    }

    function updateValue(string[] memory strs, uint256[] calldata vals) onlyOwner() external {
        require(strs.length == vals.length, "Parameter array length does not match");
        bytes32 hash;
        for (uint256 i = 0; i< strs.length; i++){
            hash = keccak256(abi.encodePacked(strs[i]));
            if(hash == 0x5dd21dd9b83dcd7edf063af02c1b497d134b1e46a09b92cb1ecb1a137bd20cbf){//keccak256(abi.encodePacked(line))
                valueMsg.line = vals[i];
            }else if(hash == 0x22574c56e2fea4d68a5e084cc2f624915952adb007bd5536b0d3f163c0b2fc5c){//keccak256(abi.encodePacked(dust))
                valueMsg.dust = vals[i];
            }else if(hash == 0xf7b50c33273c241b795a3932bb13b4b30378e09be63a90a1f33377f50982efa5){//keccak256(abi.encodePacked(dunk))
                valueMsg.dunk = vals[i];
            }else if(hash == 0xdbda963ed3253f6694e8b86667f9a0f8547d20c1a189b1ff7b4687f43f909313){//keccak256(abi.encodePacked(chop))
                valueMsg.chop = vals[i];
            }else if(hash == 0x26e85914f7727c615a62191597f3af3fa47a360525a8dca7d079fb3a75a62aa6){//keccak256(abi.encodePacked(duty))
                valueMsg.duty = vals[i];
            }else if(hash == 0xa1cc897030ceee89af92fcd534f172cd6877d6fe0587246f762147bb9cea04c2){//keccak256(abi.encodePacked(beg))
                valueMsg.beg = vals[i];
            }else if(hash == 0x02950e356cb220154678149d5e67603f6a55d9433902132d2fcf000baf6df64b){//keccak256(abi.encodePacked(ttl))
                valueMsg.ttl = vals[i];
            }else if(hash == 0x9b6659aed52f2302cecfd9981f04fc3a7cc191867abfd399d7017cb37dc0097f){//keccak256(abi.encodePacked(tau))
                valueMsg.tau = vals[i];
            }else if(hash == 0x6444dc6667642644f5b50ee1933067c2a0978c11a3f89a37f00b344803d0d28f){//keccak256(abi.encodePacked(mat))
                valueMsg.mat = vals[i];
            }
        }
    }

    function updateAddr(string[] calldata strs, address[] calldata addrs) onlyOwner() external {
        require(strs.length == addrs.length, "Parameter array length does not match");
        bytes32 hash;
        for (uint256 i = 0; i< strs.length; i++){
            hash = keccak256(abi.encodePacked(strs[i]));
            require( addrs[i] != address(0),"address cannot be 0");
            if(hash == 0x165f25927c7e5f721d75f644408dd70af077e53f04fb694f628520b2b9f9a6f3){//keccak256(abi.encodePacked(MCD_PAUSE))
                addressMsg.MCD_PAUSE = addrs[i];
            }else if(hash == 0xbe453a1b0731f5a86c93cdee952f05b27e0a23043c8d7b2fdac2045296ad3f0e){//keccak256(abi.encodePacked(MCD_VAT))
                addressMsg.MCD_VAT = addrs[i];
            }else if(hash == 0x53fd41e35530665325ff59df36a1a523ea59d01d63ff8c9323c10546d57b65d2){//keccak256(abi.encodePacked(MCD_CAT))
                addressMsg.MCD_CAT = addrs[i];
            }else if(hash == 0xcde1ee473d5de5e41329447b2d7edc95e5243cf44a2a8991fa3497a455252054){//keccak256(abi.encodePacked(MCD_JUG))
                addressMsg.MCD_JUG = addrs[i];
            }else if(hash == 0x483a23c81ac9122fb7820cf2b6cbc0b9ed75a3adc6e0e469d6cbc1163ec83d48){//keccak256(abi.encodePacked(MCD_END))
                addressMsg.MCD_END = addrs[i];
            }else if(hash == 0xe93dd2d6754e89fd195487d1c29326f45578459a24539a9e973093a40e0155a6){//keccak256(abi.encodePacked(MCD_SPOT))
                addressMsg.MCD_SPOT = addrs[i];
            }else if(hash == 0x2295cee8313bf181f5da9e55659723fb2330f71c6b0bbd60da91148ddf97d74a){//keccak256(abi.encodePacked(FLIPPER_MOM))
                addressMsg.FLIPPER_MOM = addrs[i];
            }else if(hash == 0x2dca508aa1fb7af5ae9a04a537d4283f2c5fef63a4df564ee80bec6da81bb906){//keccak256(abi.encodePacked(ILK_REGISTRY))
                addressMsg.ILK_REGISTRY = addrs[i];
            }else if(hash == 0xcb2a941d943e9c5f66f6bf44a553c3dc83e8be0c3790e8b99a5f62e42e5861c5){//keccak256(abi.encodePacked(ILK_DEPLOYER))
                addressMsg.ILK_DEPLOYER = addrs[i];
            }else if(hash == 0x5c3fc3bb988787f28c6c470a6a5a9c0f98ee5723e6cc3a66dd1cdaf7d6ced639){//keccak256(abi.encodePacked(FLIP_IMPL))
                addressMsg.FLIP_IMPL = addrs[i];
            }else if(hash == 0xfdaaa699ee978b54a69b5181e9e3d471e80e9b73342f761fb149ecb7da40c6fd){//keccak256(abi.encodePacked(JOIN_IMPL))
                addressMsg.JOIN_IMPL = addrs[i];
            }else if(hash == 0xb8c1be922aeacf00a108713200328f15180b2a32d310eda1c180377598120174){//keccak256(abi.encodePacked(PIP_IMPL))
                addressMsg.PIP_IMPL = addrs[i];
            }
        }
    }
}