// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract C2EToken {
    using SafeMath for uint256;

    string public constant name = "Connect2Evolve";
    string public constant symbol = "C2E";
    uint8 public constant decimals = 12;

    mapping(address => uint256) internal balances;
    mapping(string => address) private idToAddress;
    mapping(string => uint256) private idToShare;
    mapping(string => uint256) private idToClaimed;

    uint256 public totalEnergySuppliedInKWh;
    uint256 private _totalSupply = 1000000;
    address private admin;

    event Distributed(uint256 totalEnergySuppliedInKWh);
    event Claimed(string userId, uint256 amount);
    event UserAddressSet(string userId, address userAddress);

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert("Only the contract owner can perform this operation");
        }
        _;
    }

    constructor() {
        admin = msg.sender;
        balances[address(0)] = _totalSupply.mul(10**decimals);
        totalEnergySuppliedInKWh = 0;
        setShares();
    }

    function setAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.mul(10**decimals);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function unclaimedOf(string memory userId) public view returns (uint256) {
        uint256 totalShare = (totalEnergySuppliedInKWh.mul(idToShare[userId])).div(10**decimals);
        return totalShare - idToClaimed[userId];
    }

    function setAccount(string memory userId, address account) public {
        if (idToAddress[userId] != address(0)) {
            balances[account] = balances[idToAddress[userId]];
            balances[idToAddress[userId]] = 0;
            emit UserAddressSet(userId, account);
        }
        idToAddress[userId] = account;
    }

    function getAccount(string memory userId) public view returns (address) {
        return idToAddress[userId];
    }

    function distribute(uint256 newTotalEnergySuppliedInKWh) public onlyAdmin {
        require(totalEnergySuppliedInKWh < newTotalEnergySuppliedInKWh, "Report value should be greater than previous");
        totalEnergySuppliedInKWh = newTotalEnergySuppliedInKWh;
        emit Distributed(totalEnergySuppliedInKWh);
    }

    function claim(string memory userId) public {
        require(idToAddress[userId] != address(0), "Account is not set for this user");
        require(idToAddress[userId] == msg.sender, "You can only claim your allocation");
        uint256 unclaimed = unclaimedOf(userId);
        require(unclaimed > 0, "Nothing to claim");

        balances[idToAddress[userId]] = balances[idToAddress[userId]].add(unclaimed);
        balances[address(0)] = balances[address(0)].sub(unclaimed);
        idToClaimed[userId] = idToClaimed[userId].add(unclaimed);
        emit Claimed(userId, unclaimed);
    }

    function setShares() private {
        idToShare["map100erzf2hk6s6xcq30qtfc6znrh7l4f7v59w9md"] = 97000000;
        idToShare["map104wmvan7rf3k42lg7z60uxdccmerg63zzc6lf4"] = 32000000;
        idToShare["map10cfd3sq7qscms2vd7dfk2u6tntafn2g5qk7xhn"] = 522000000;
        idToShare["map10j63760gq70dwmfl04yaqmv3zcvmsxcalezhjt"] = 82000000;
        idToShare["map10jycpv4hl2p8yugha66hast2v5pkd8uyh68vup"] = 327000000;
        idToShare["map10k9647jdzc4ryv2awqh7uwfuwqk9yxk90pawsw"] = 163000000;
        idToShare["map10lmwp34drdgmdkg3yk6pzvx4enl3l8mkp6a3fv"] = 859000000;
        idToShare["map10sv5lpkp3ywqqk5plt44fjympequmr3r3uqqy3"] = 65000000;
        idToShare["map10x7pve3h7x7aqvcrqyvza042caq39frvphtyj6"] = 261000000;
        idToShare["map10zk49zdpzss5dmakfc0sys62xt8j64lep5pfp3"] = 295000000;
        idToShare["map123derkqmj40ddg2xfgt2pas74nunh52vh3m674"] = 330000000;
        idToShare["map1290q9kjt58qg4jk5zfu5g0k8eh3d2ugkjs5yrm"] = 92000000;
        idToShare["map12cdw4p8xv90f0d06tkd0ugdf7y4eapg5ldn0ry"] = 261000000;
        idToShare["map12cv79kg6e2vg6ykvyez7xa36glymc46eln7jjw"] = 148000000;
        idToShare["map12dcn8ylhawkg4cq9n57c049vewcazef73mpdra"] = 58000000;
        idToShare["map12u0jzmnfy7vs7setq54knxwuaelqk4py57hp2k"] = 32000000;
        idToShare["map12udls8fwaqjf5r99vrl6d0709y9gne7uhw3593"] = 327000000;
        idToShare["map12yq6rhtleevjrkd0h9lsmvca9a6zq2khfulcdy"] = 163000000;
        idToShare["map137gv76ccy7nlyyqvfpx4sde64fch2vak7hqgg6"] = 163000000;
        idToShare["map13jnu82a2mdt7urdg4ytyncf4cwxh6zvxz35flj"] = 136000000;
        idToShare["map13kqp3q90wv4hs9mz2c3zq9amjcvq4qr2tsmdc6"] = 38000000;
        idToShare["map13phchqqmdmje99n8fganxzevumwt50sklkl7e8"] = 32000000;
        idToShare["map13wxwlk6eacdw0vqxsd3dx0al9z4scjdqkgaf37"] = 65000000;
        idToShare["map1446pscg0gg7mn56jmhky64jxercv6phamet6z8"] = 163000000;
        idToShare["map144vqpmn8x6wkjp4f9r0pfn322y88xdr7md9p2y"] = 54000000;
        idToShare["map14jcpv798s4565fnphqgp8z8ea39chl2l5g0w5d"] = 163000000;
        idToShare["map14jersy96wuwucxr70erxcjnnxdkeyfx9gesaaw"] = 327000000;
        idToShare["map14k2f9sfc3uqaa9jr7cdel6l0hqr5ujha4854gx"] = 163000000;
        idToShare["map14tpl26g6sgy9uln5xq8cesqx8jla2jlq06v22l"] = 32000000;
        idToShare["map14vmckq7g5alf5hex4j2ct686vq204qy95g6wet"] = 330000000;
        idToShare["map15d8he8yg08xxm2g0mj2fwdj9sfq5ra2943ecue"] = 654000000;
        idToShare["map15gr6mey5pc8pmc80x0ae3m8m3g8f2x6fchqxff"] = 97000000;
        idToShare["map15md5ps6ealkp4cjn6lrhjc2s4y9sv35a895sma"] = 297000000;
        idToShare["map15pf99km55h4fk3fjppt6tpp2uvfefr6ckr7m4s"] = 105000000;
        idToShare["map15psuyjyczzaltywpue4k6gn0kvnjtamkngm790"] = 984000000;
        idToShare["map15pv0jmjrwzhvtqhk27tp6axlnj7kv23v8uem0y"] = 323000000;
        idToShare["map15qpsrzesjnyflmyhwkdpp5d9d8gwtk6g2g2jme"] = 196000000;
        idToShare["map15y2evk6njv5x8t8yt9d9arwks8lkmcdu7hkghk"] = 32000000;
        idToShare["map166zsys6cj898k7dkyctyr98x9tcm4rxrj2wgdj"] = 327000000;
        idToShare["map16dh78ama6vvacrsgxjckkcdp3v7mx5gcyfsfey"] = 163000000;
        idToShare["map16frdp0hekyc4uhff8ygqugw2ewg5twvqzhmcs7"] = 327000000;
        idToShare["map16hh4rxy20vgvuywqvrms653f9evgwkv85tq43m"] = 326000000;
        idToShare["map16kh9z7cavkh5juu24a3g7uak66dseku6llhta6"] = 80000000;
        idToShare["map16qt6g7dahufvu4ym72hx5yhu2unahafma65c87"] = 65000000;
        idToShare["map16qupwac8datadpf8pxlg0f9jrhncz374qhu3j4"] = 327000000;
        idToShare["map16s6plfk3nz5wfhpy2rvadvran6q78a8dkhtyn5"] = 97000000;
        idToShare["map170457usx5yt9rchc8758gkhsq80kqt85qfwxys"] = 32000000;
        idToShare["map173w2u3en6j3a9uvayzkm2e07pk64n9rh9tgfqv"] = 397710000000;
        idToShare["map175qves647536n20pvyppc32k93k0k5sx667849"] = 39000000;
        idToShare["map17djxdtmfn4enyyn78cxvd2vwxx357cufdrde68"] = 32000000;
        idToShare["map17l2l2h6yx4gk7scnlqs4wk4gxttq4v5nar6p6e"] = 827000000;
        idToShare["map17m6llnmj57gqlx36lzmgnuuk2guctpma4ked79"] = 163000000;
        idToShare["map17na75wme3e63z6v7n6r9kjnnu86thw0ryrua3d"] = 163000000;
        idToShare["map17nnq0sxr9cs28r0qqlutkqn3kacfmlz7aatmpf"] = 327000000;
        idToShare["map17sqytx2vmqrtrpnyyury25jkazu4zw46fun4za"] = 228000000;
        idToShare["map17y44ylht47dp8kuaexwdr4dsl3tnfehg3d89m4"] = 321000000;
        idToShare["map1846rurx4l080rwkwtf2q7mqvcf2u4mlfkswn7h"] = 65000000;
        idToShare["map188pc04s0rwkpkvrkujymjtyw2hpe2wkl6dnucx"] = 32000000;
        idToShare["map189gdttye7hczz8h8kmyc6pu6gmf8aty99mhrvl"] = 65000000;
        idToShare["map18anshdys39022v4sm8ftrn46nm7qtuanglq2ac"] = 163000000;
        idToShare["map18c0wen85q8flgj2slx4c3j2serly2dfttd7gwl"] = 327000000;
        idToShare["map18tsezdpl7rl0tka8vky97dnfrd8s09xwcm53xy"] = 65000000;
        idToShare["map18vr4z4eln9l5hnrj8z03yrtsqxxcmp40ns338h"] = 490000000;
        idToShare["map18xam97c9uqs2wt6p672gf3mvzphuv9tlsp3xmu"] = 163000000;
        idToShare["map196v0nwhs33vtl84ak9a7ztd0c7c3h2qys3dw8h"] = 65000000;
        idToShare["map19clp608wmv7l8xv8h5w7x3w0384crtxgvkq5vx"] = 1688000000;
        idToShare["map19fyfdetwwpau4rs8lykre7d8ufkrae8944kf48"] = 31000000;
        idToShare["map19hfzzuuyqzsqqxqywauskw7q27w3rcqf6rcj0n"] = 179000000;
        idToShare["map19jzvd8q3dhskymmfynhnj66k2kygzezxpc2eq3"] = 163000000;
        idToShare["map19mtw54yjslnm3a40nz7kjw237wnpkzpu3v0vad"] = 32000000;
        idToShare["map19sevagtx556ygmfgsltn8m7h5w8cmym6fqf6wl"] = 65000000;
        idToShare["map19vm5tpc58az9u2duj6u2h2gw5jg8dakl0synjm"] = 48000000;
        idToShare["map19ycpw092e36wmq58npzt6s90xr5zfcrjj93v0j"] = 654000000;
        idToShare["map19yka8f2cj9e6jq3qhxrmsf05yqy594ujng5vem"] = 81000000;
        idToShare["map19zhsu2kfl7ts0akamgmwv6vzmdrq4kc64mjv2c"] = 68000000;
        idToShare["map19zmfzzuf2r8269xtwnq43jkza9vmrhrp9m9hau"] = 718000000;
        idToShare["map1a3n6sstgn6lfqusah646749jkce7gens30y645"] = 635000000;
        idToShare["map1a3yk5g9mdlnds6wh5kaaun9yssx7jmgn6aqpr0"] = 3846000000;
        idToShare["map1a5j6xl30uk3u6eap5hm6npzrrtcma6e7zye7er"] = 653000000;
        idToShare["map1a6vn77cda8naz234kxcnt4upmeya4y26d2dz6d"] = 327000000;
        idToShare["map1aag8q2duu2djmdsvjyr6zd87pslyusd2m9za9e"] = 662000000;
        idToShare["map1aeld2u4tcxqdvlauygwjg9fryrtvdvzdhr2a8u"] = 163000000;
        idToShare["map1ag9dr6k6s3jw3rfjdu0mkrdkcatvr8da8x5ma7"] = 130000000;
        idToShare["map1c07erff875qdy5e6gkaetvzhlh97ytpcx04eey"] = 65000000;
        idToShare["map1c5x79m53f8kqqxqll5h936y3f27kd0742v85sk"] = 1696000000;
        idToShare["map1camx5epjya6z2r5dwj88wqt3ffr3txup8sq9zm"] = 163000000;
        idToShare["map1cfgzhs0kgmtppgrya88xf7wq2qvphekj80a32f"] = 327000000;
        idToShare["map1cn9npszs3ar3r724c0dwg2hh5g6n88g5k4jp2l"] = 662000000;
        idToShare["map1csuaqjcfu8skkc8q3yahc3ky9934ulvz9an5l9"] = 32000000;
        idToShare["map1ctuynae3rm8423ujcnm27q6w4263v0gd5wzm0z"] = 179000000;
        idToShare["map1czh8qg384v850r6xduhytezr5mspca9zj5rzew"] = 32000000;
        idToShare["map1d3y02g83w9ux52r67sgn7a26j2e7p5cs654agr"] = 65000000;
        idToShare["map1d98g7te9w3wltqu90udqhnascc8rdyerf2826a"] = 327000000;
        idToShare["map1damrpn6p06lxyaedqx2vyrdrr6xdzzu4a4sqtp"] = 65000000;
        idToShare["map1dej5tkek2azulfz3zsgy0d44jms370eke8zwsh"] = 65000000;
        idToShare["map1dgem3c50q7h0d9xjff49eznmzyyh26vvrgp23g"] = 32000000;
        idToShare["map1dp0uya5vwvshxpnjecge0z2tvpvhm98tuw6752"] = 64000000;
        idToShare["map1dq34pehhj6r6u3kuq2xs9c9vj3fyyvd7p8qx6w"] = 160000000;
        idToShare["map1drxgjyr8s5frtkvc23ng5ep68hsknzml4kwzhj"] = 163000000;
        idToShare["map1dur2fr43p93ukm8yd43rpxcxf27r8wvyh80kud"] = 327000000;
        idToShare["map1dv9w684pa2nwv0xrjjqwn087cazldyxadrqh8l"] = 58000000;
        idToShare["map1e0szlv78e256m8fk5cxj7nhc2y2wst6ls6qs99"] = 163000000;
        idToShare["map1e8k9pft46pk9y34ajldsfl7mgrk8775fp9cgkd"] = 82000000;
        idToShare["map1eep308zap8pm3k50pze5dkx97qfzr2p5pkmmzs"] = 65000000;
        idToShare["map1eewnlu2s80carg4ehwmetakpsrx02xc04gp3s6"] = 523000000;
        idToShare["map1ej5apw45v3a55qaradsjyxslq4ej5rshg8sxx0"] = 31000000;
        idToShare["map1ejf3k0d8ruafsjp52hfn0qk78n359vd60256z4"] = 818000000;
        idToShare["map1ew5955n95mye5p84900j84whdx9adagnzft4ux"] = 32000000;
        idToShare["map1eyc0st0e50vu5y8mfkyv5z2txgqezhx6e9ln76"] = 31000000;
        idToShare["map1f6vlp04wpg9nu5z2swl9xkuvac0d68ra734cm6"] = 163000000;
        idToShare["map1f9ungn7hjt945m69eypc9n659p8jgv5r5fzp2a"] = 59000000;
        idToShare["map1ftcfejnn5sv7wqg36mtxxum450w24zpyxq7mgg"] = 485000000;
        idToShare["map1fw92jng3xjd985tn7tka3704x5mf9nemhymc9z"] = 32000000;
        idToShare["map1fwn4ww7cptg6a0vpcd69xxa998wc4uktv8uzkc"] = 662000000;
        idToShare["map1g5un59n40c3uf7ptpjz7r2c0s0jhvzlxsuanyp"] = 136000000;
        idToShare["map1gaj4jvjj8m6354fj8v5ex4rnfl9lempjncgjlr"] = 163000000;
        idToShare["map1gh5ldzk64s052xmxmmu854afqmgesygq3tzg0c"] = 81000000;
        idToShare["map1glj2yep02hjc5eael7r47fp84grf2cfh4xr0rw"] = 65000000;
        idToShare["map1gp4rxy24jkvxrk40tprll7cnksfe3uyrx2dm7k"] = 326000000;
        idToShare["map1grzup32recva5nt9c9z2jgysfwy36lre0nzafy"] = 1636000000;
        idToShare["map1gx2zj7a4kqjcqq9t6va4zjun4gn2z30wmlqht0"] = 165000000;
        idToShare["map1gxc8p3gfc4k8nq73v4kc6wl8cdswl8ethgy9pp"] = 163000000;
        idToShare["map1h4kkhtez79ddypa254jq0h8x8yqncedtj3fxuq"] = 1770000000;
        idToShare["map1he3xhkwkkkmmvflkxwv39mmh5gykkrh5hh2u27"] = 327000000;
        idToShare["map1hhl85dscdrh5cu5lg9t8scj450lcej09wgrjjn"] = 97000000;
        idToShare["map1hlm5azxpwa790l4ge3jzppglps95r7p5z6jxhz"] = 160000000;
        idToShare["map1hnmuuwpvenvjnpy6rnfw98gqj6ywgacf96kspd"] = 32000000;
        idToShare["map1hz4gzcyujtq2nw0zg59rv76gtz34kklm3nn49s"] = 165000000;
        idToShare["map1j0s7mdw2pc24z8h0k4yqywju6f2nna0guahlhm"] = 31000000;
        idToShare["map1jgjhg369tfscp65gue2x6959alxrj30j39t0p9"] = 160000000;
        idToShare["map1jnr0k360mm25wj99m08jfjlan768ypmez9zsc0"] = 165000000;
        idToShare["map1jwursryn3mnaxcnka40dkzy5hkwtcgtdnukwpe"] = 51000000;
        idToShare["map1jzvk5mxfx7r4lfngqr2p7l263wzqmf8hu5m2p4"] = 163000000;
        idToShare["map1k86p3m4j8cffxdl6vccyq9nha65jh5aetpnlqu"] = 514000000;
        idToShare["map1k90u3kc5gredu7lpts93yyclp4ac5tssrtrth2"] = 163000000;
        idToShare["map1kprkzscu5kmq94ldg9k7s0ck83lcmvrx88gwcy"] = 32000000;
        idToShare["map1kq6w4mn8lyx3rkfvdpxgypqlqm86gatl67hhlp"] = 97000000;
        idToShare["map1krdy0pwa8lnn6wa5w886s3zfjlf7eky5acxj7z"] = 482000000;
        idToShare["map1kvzxsfps8plvw57v7ug9tfgum9qh00fcnkxepa"] = 499000000;
        idToShare["map1kw7rm265ag6yrwt8defgy88sqhnzdcf9xsacfv"] = 31000000;
        idToShare["map1kxecjuu8u2wlwhwpkhfr6uvzcv5l5s82ye2rf7"] = 65000000;
        idToShare["map1l7g7w34vgp0xhkacyzj363wgpz9cfejrsh70jt"] = 330000000;
        idToShare["map1l9ckvdwl3ycvsqy66s6us4kf0jv9q447yaf6mc"] = 653000000;
        idToShare["map1lglx6fvrqdm0gv2049da8ep2rz7syk9gpdmwu3"] = 1487000000;
        idToShare["map1lleswn88j3w3zfp2kgk6djnzjsynhgjut7j06r"] = 65000000;
        idToShare["map1lp0ex0gpe5yvne6nsh3dkf6h4yymsh4pgl4cf4"] = 327000000;
        idToShare["map1lp75sldj60pegeutthcaxkl6rqdt8xpmyvgf4e"] = 73000000;
        idToShare["map1lqkf2kayw8l6rllddzv0krx33qzggucg3avle4"] = 61000000;
        idToShare["map1lznhjrzvc42sym9mhuxtu803k8w9m2d2rc2rvl"] = 65000000;
        idToShare["map1m2zf50fplh34usavwg7akzn7w23cgpmcp0mpks"] = 35000000;
        idToShare["map1m8wgkvt8kzmy3r3vd4luuuyu6m5yvdpwupwc9m"] = 97000000;
        idToShare["map1maj3mtxky94yp67mkfhm2htk330djpwuwf5873"] = 163000000;
        idToShare["map1mau7mtuymc9klvsraxnzq800g25gzet2fr2smf"] = 719000000;
        idToShare["map1mfz36srraylfehkngq9qsevrutmnk03gtfymv7"] = 1821000000;
        idToShare["map1mm6z7r3edx0z4e5jtp7vrh3ztr20zy2erp9vvf"] = 330000000;
        idToShare["map1mshdayk3yyrx74avfvp8nydg3qanp5ct5upv5r"] = 148000000;
        idToShare["map1n43a2wppsae7gnu5r6nx73fntmwgq63pwnjpt5"] = 327000000;
        idToShare["map1n5xm09d0rprppvmr720ahhpkp49tuz52gzaph6"] = 152000000;
        idToShare["map1n8jy5wnag0398c0elgjht6see7eh44lv02kmhq"] = 115000000;
        idToShare["map1na603typrknr7xuejcs5mnynwxafju9zf84jd4"] = 1636000000;
        idToShare["map1ncs2jmwucraqnse4f3fjexhw8f35aaye9t6hkn"] = 81000000;
        idToShare["map1ndly60pnh4qln0za0geauau2fkfrtge0l8r26e"] = 32000000;
        idToShare["map1njn2nscydp8l8q2kcx44lqy8hp2snggv63kzkm"] = 165713000000;
        idToShare["map1nkjp5dw0naf05h90sudmx6g9jkg8ax3z2vxy4g"] = 58000000;
        idToShare["map1nnl0zvn9fg8uhtqcfll2hemckjhyjl077s4hfs"] = 97000000;
        idToShare["map1np9y2y04vx0rma5yrn4grk8jq9cu65pwvndsqm"] = 65000000;
        idToShare["map1nt8g269l2e4rkevfjt6kzpxqpuzsx8vcm5k2gc"] = 309000000;
        idToShare["map1nzpqjfu4wgmjvyjczhj6wjrlvhyfje3stys2ev"] = 163000000;
        idToShare["map1p2kuz6txv9k586qsz9xskecc2g6845vuz89g4k"] = 32000000;
        idToShare["map1p340c8u49ke2cpswchxm8rx69v4c604e3aqnv8"] = 330000000;
        idToShare["map1p390m690lycy6ksg84r8kt7v9p8nppg59c7fqc"] = 490000000;
        idToShare["map1pep5yvqhlyakh25addxdtam8hcrs5zlfzlad2n"] = 154000000;
        idToShare["map1pk0fr34rhzzxevgngtd7mj0u0wjnjjlk5rxgag"] = 33000000;
        idToShare["map1png6fl9srh3838t3sa73g2a90gtyrul8ce4702"] = 198855000000;
        idToShare["map1pp3wvza20758qyk82krmyuchar09elcjdhyvlf"] = 148000000;
        idToShare["map1ppj3sx5vxrls446f2v2aj9psdtsuf8m6tcqruz"] = 32000000;
        idToShare["map1q2crd6tdws787gxdrgzvljl0w30ylgm8en9cv3"] = 327000000;
        idToShare["map1q37l449p73z4jc5qzg3ky6ujrsmshzyft4pmpz"] = 289000000;
        idToShare["map1q6zf2cnywhquegrx04ptgh8dn4ss7snrgqujnc"] = 330000000;
        idToShare["map1qcqpzrjcxke078pvmf9ysjfh8x2yd936jajfy0"] = 144000000;
        idToShare["map1qdd74v0y9pxdqml8urmg503dvdtz9nnqe5avh8"] = 32000000;
        idToShare["map1qghn2jpm5dn98v7ldf7fznpn0z5xpqx32j785v"] = 147000000;
        idToShare["map1qjpvew5eesgcaj0vmsc8fkqctmgqxlcennfj34"] = 662000000;
        idToShare["map1qnwm294ft8zyvafgv03u7vp57yf6xyrds2wa3x"] = 65000000;
        idToShare["map1qpzqj9f2du7ffhqlrmgw3a535p43nchv6ucg4s"] = 97000000;
        idToShare["map1qsn90hf0yn4gyjtqt95r9a4xvy2z3x86ks6wye"] = 32000000;
        idToShare["map1qumkdcrz9yzdvhaf3xu8k4zmtht0fvx3nvnqtu"] = 65000000;
        idToShare["map1qur8en0j6ls6y8vfmnh4ta9lg4xw70v6wjg4wm"] = 816000000;
        idToShare["map1qwrm7u5z5t9mhzl34uanf7auwhd82jqrjk0phc"] = 296000000;
        idToShare["map1r6y7wvlzgrem8wmcg6yx6w5lhn565h3r6gen2n"] = 321000000;
        idToShare["map1rhcs4sjgyq5z6lsrdkxx0m2m3vuwd9lvq9sm5w"] = 163000000;
        idToShare["map1rk06wznepr4cqgadaqmf43djdpk2vyfu5l5v7g"] = 327000000;
        idToShare["map1rurhhqmh9fnh5thcwnc4rlymrkehf8tct33uh7"] = 65000000;
        idToShare["map1rwcftw6ha52ter5te2h6jmwd9pe48rqs42jhvc"] = 81000000;
        idToShare["map1s4s9tjytalq4csp78l7fx2cucqs6wuhwhzdxyk"] = 654000000;
        idToShare["map1sc8g2866h37vz3aamqlny0ngrxngmk0p8lqcu6"] = 97000000;
        idToShare["map1scvcvmulx3cmw7h6lkrug0zkh3gvsnaxpdkvsd"] = 327000000;
        idToShare["map1sf46fccgqjm7csa3gzl8ecsj22yk0sd43pwdwy"] = 144000000;
        idToShare["map1sjtfsvz3lkdq2teee9tapc0xrru08xd5rva4ca"] = 326000000;
        idToShare["map1sqk4pyvsyf43p55h2ly007sjql6tdav8damfh3"] = 133000000;
        idToShare["map1ssnc5t42q3mh3c2vnwnzq2ldddjefw7du6rk3s"] = 264000000;
        idToShare["map1t4y7nfzwkgz3y38plvd0caz93hx8pleuswmndt"] = 65000000;
        idToShare["map1te477x3qfeklgz2y2vpp26vc93uadg2cjyttpv"] = 165000000;
        idToShare["map1tfp437gefsgqmnatt70mg4nfdazm7ete8687ts"] = 163000000;
        idToShare["map1tgdfa6cqxzkwfuz0gzv7s7ekzc9dffmq4jjq5t"] = 163000000;
        idToShare["map1tkvex84jq8d3q22qm8t2ge8st0e0ukw0pgen35"] = 97000000;
        idToShare["map1txdygjz3qj05xp0e7dwl6knfp2hspjy8vuezrx"] = 6359000000;
        idToShare["map1u8lepktmgr4g2mlvs4qyu9yy8dfzzfnna5cxkd"] = 321000000;
        idToShare["map1uevwvz8nwpy5wv3p2hmd6fwtkruzf87npp3rcv"] = 327000000;
        idToShare["map1ugzhzs7sxhgdvf2rkjg4wj3k420s62tteasldp"] = 65000000;
        idToShare["map1va4x3fjfjkhhn825ls4rqdk22v09gzmdet3znx"] = 523000000;
        idToShare["map1vd58k5xjjvye9l7qpl04x6pjzzm8s7j2kr5v7d"] = 65000000;
        idToShare["map1vne2n2ssrjzazzx5ewttsaxwxj4d5vwrf4qeqm"] = 49000000;
        idToShare["map1vredum5l73u9vx8zrf6zmwvm62k9vdjdvtrw2r"] = 2021000000;
        idToShare["map1vzxlh4uxnwf9d8c5ylqc4xxpgtj5y84rthsdm7"] = 65000000;
        idToShare["map1w4uklj00zfddyv6tp8gz0rpj2w98pja7nlwe09"] = 327000000;
        idToShare["map1wc09kelejatz2lepqj6p6r8n4qwj6hhkgpu642"] = 165713000000;
        idToShare["map1we4pl4twvpuzp22y7awthpxn4ryt2gayld6ety"] = 321000000;
        idToShare["map1wekd4xr0t7ggj47wsun9nr024ltsnzeyspk0gc"] = 163000000;
        idToShare["map1wf9srz7drs3u8tvr4mx4x4lw3vr6wnesqmn2f7"] = 643000000;
        idToShare["map1wqgz9kkmr7hp0msha9rlmxuqal745570s4mzd9"] = 327000000;
        idToShare["map1wtp53ra0j7jwzd4gzgfml3f930ggjgtayzsst4"] = 498000000;
        idToShare["map1wx7xrvly8d9e3tt0f4jfkujq3hm9evxm5ecvlw"] = 32000000;
        idToShare["map1x7gn5keenhdaaqscy6c97tlqa8297syn4scgcw"] = 65000000;
        idToShare["map1x7rjqntxvfssa2ksp05pu4wptrz70k7gs4frtp"] = 163000000;
        idToShare["map1x8lgf0dt9388eqfcsf8meyf9dmp6a90hprc0vn"] = 169000000;
        idToShare["map1x8qqdsxglsvyesecaqqnn6gjd2swuvp9gwvsaf"] = 231000000;
        idToShare["map1xlazcet3r7g90k8gtj2kddaenzdwsmuq7353cu"] = 163000000;
        idToShare["map1xnu6npuq85r2gvhkddyy6cem9j0hp9umul63n5"] = 165000000;
        idToShare["map1xu66fvsnyykhcw00kmmktme56seg67q6tmadyy"] = 327000000;
        idToShare["map1xv0zpvdppsqxnj3yyn0xtrvwff9kkpuvhqk9kf"] = 163000000;
        idToShare["map1yjaazkvvt97cg527svura6d3gcljvy0cvjd95h"] = 163000000;
        idToShare["map1yv7auhm2h23f2lpdgj98yacddsuf9urnfr95f3"] = 163000000;
        idToShare["map1z8dalshjn9de0qcqggy7du9jhrn832ur9vtcav"] = 65000000;
        idToShare["map1zctav26nq3kje7pz4dqspkjjdlhwjhlqungaz7"] = 330000000;
        idToShare["map1zgrpvwel7hne8n55x20ptnnwjmjqyazz28uk06"] = 163000000;
        idToShare["map1zjgzk060jysve43ja9narcz9flw559fprktr6a"] = 327000000;
        idToShare["map1znk9cdukz8wktegah02ruz9e60y5e5vuvc6d62"] = 32000000;
        idToShare["map1zrzny77xp9dkfwdgs085j275w467ece2a3n5nq"] = 165000000;
        idToShare["map1zw0yx9emp4nfnjkg7axxrt4uedt46f8vzcmq56"] = 165000000;
        idToShare["map1zxarrqck36p5g7g9ej7qte2wz63mld33hecc2n"] = 163000000;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}