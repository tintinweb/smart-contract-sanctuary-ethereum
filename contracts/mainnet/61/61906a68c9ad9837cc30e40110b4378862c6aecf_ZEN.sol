// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zen Bird
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    ;:::;;::::;;;;;::;;;;;;;:::::::;;::::::;;;;;;;;;:::::::::::::::c::::::::::::::::::::::::::::::::::::::cccc::::::::::c::cccccc:cccc:::ccccc::cccccc:::::ccccccccc::cccccccccccccccccccccccccccccccc:cccccccccc:ccccccccccccccccccccccccccccccccccccccccccccccccccccccclllccclllccccllccccclccllccllllloolllcc    //
//    :::;;;::::::;;;;;;;;;;;;;:::;;;;;:::::::;;;;;;;;;;;;;;::::::::::::::::::::;:::::::::::::::::::::::::::::::::::::cc::ccccccccccccccc::cc:ccccccccccccc:::cccccccc:ccccccccccc:ccccccccccccccccccccccccccc:ccccccccccccclcccccccccccccccccccccccccccccccccccccccccccccllcccccccccccccllcccclllllccllllllllcccl    //
//    ;;;;;;;;:::::;;;;;;;;;;;;::::;;;;:::::::::::;;;;;:::::::::::::::::;:::::::;:::::::::::::::::::::::::::::::::c:::::::::cccccccccccc::::::ccccccc:::ccc:::::cccccc:ccc::cc:::c::ccccccccccccccccc::cccccccccccccc::ccccccc:cccccccccccc:cccccccccccccllllccccllccccccccccccccllcccccclllllccllllccllllllllcccl    //
//    ;:;;;::;:::::;;;;;;;;;;::;;;;::::::::;;:::;;;;;;;;:::::::::::::::;;::::::;;::::::::::::::::::::::::::::cc::::::::cccc:::cccccc:ccc:cc:::::ccccc:::cc:cc::::c:::c:cccc:::::::cccccccccccc:::cccccccccccccccccccc::ccc:c::cccc:::cc:cc::cccccccccccccccccccccccccccccccccccccccccccllccllllcllllllllllcllllccc    //
//    ;;;;;;:;;:::;;;;;;;;;::::::;;::::::::;;;::;;;;;;;::::::::::::::::::::::::;:::::::::::::;:::::;:::::::::::::ccc::::cc:::::ccccccccccccc:::::cc:::ccccccccccccc:::::ccc:::::::cccccccccc::::cc:cccccccccccc::ccccccc:ccccccccc:c:::cccccccccccccccccccccccccccccccccccccccccccccclcclcccllcclllccllllcccllllll    //
//    ;;;;;;;:;;:;;;;:;;;;;;;;;::;;:::;;;;;;;;;;;;:::;;;:::::::;;;;;:::::::::::::::::::::::::::::::::::::::::::ccccc::ccc::::cccccccccccc:::::::::::::cccccc:::ccccccccccc:::::::::cccccccccc:cccc:ccccccccc::ccccccccccccccccc::c::::ccccccccccccccccccccccccccccccccccllccccccccccclllllllllccclllcllllcccccllcc    //
//    ;;;;;;:::::;;;;;;;;;;;;;::;;;::;;;;;;;;;;;;;::;;;;::;;::;;;;;;;;;::::::::::::::::::::::::::::::::::::::::cccccc::c::::::::::::ccccc:::::::::::::::::::::::ccccccccc::c:::::::ccccccccc::ccc:::::cccc:::ccccccccccccccccc::ccc:::ccclcccc:ccccccccccccccccccccccccccccccccccccccccccllllllcccclcccccccccccclc    //
//    ;;;;;;::::::::;;;;;;;;;::::;;;;;;::;;::;;;;;;;;;;;:::;;;;;;;::::::::::::::;::::::::::;::::::::::::;:::::::ccc::::c:::::::::::::::cccc:::::::::::::::::::::ccccccccc::ccccccc:::cccc::c:::cc:cc:::c:::::cccccccccccccccccccccccc:cccccccc::c::cccccccccccccccccccccccccccccccccccccclllllllcccllccclccccclllc    //
//    ;;;;;;::::::::;:;;;;;;;;:::;;;;;;::;;::::::;;;;::;;:;;;:;;;::::::::::::::::::::::::c::::::::::;;:::::::::::::::::::::::c::cc:::::::cc::c::::::::::::::ccc:ccccccccc:::::::ccccccccc::::ccccccc:::c::::::cccccccccccccccccccccccccccccccc::ccccccc:ccc:ccccccccccclcccccccccccccccccccccllccccccccclccccccccc    //
//    ;;;;;;:::;;:::::;;;;:;;;;::;;;;;;;;;;;;;;;;;;;;;::;;;;;;;;;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::ccc::c::::::::::::::::::::::::::ccc:::cccccc:::::::::ccccccccccccccccccccc:::ccccc:ccccccccccccccccccccccc::cc:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ;;;;;;;;;;;::;;;:;;;::;;;;::::;;;::;;:::;;:::::;;::::::::;;;;;:;;;;;;:;;:::::::::::::::::;;:::::::::::::::::::::::::::::::cc:::::::::::::::::::::::::::::::c:::c:cccc:::::::::cccccccccccccccccccccc:ccccccc:ccccc::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:cccccclcccccccccccccc    //
//    ;;;;;;;;;;;::;;;:;;;;::;;;::::;;;;::;;::::::::;;;;:::;;;;;;::;;;;:::;;;;::::c:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::cccc::::::::ccccccc::cc:::ccc::cccccc:cccccccccccccccccccccc::cccccccccccccccccccccccccccccccc::cccccccc:ccccccccccccccccccccccccccccccccccclccccccccccccccc    //
//    ;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;;;;;;;;:::;;;;;;;:;::;;;;;:::::::;;::;;;::::::::::::::;;::::::::::::::::::::::::::::::::::::::ccccc::::::::::::::ccc:::::cc::cccccccccccccccc::ccc:cccccc:::::ccccccccccccccccccccccccccccccc:ccc:ccccccccccccc::cc:ccccc::cccccccccccccccccccccccccccclccccccccccccccccccccc    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;:::::::;;;;;;;;;;::;;;;::::::::::::::::::::::::::::::::::::::::::::::ccccc::::::::::::::::::ccccc:::c::c::cccccccc::::ccc:ccccc:::::::cccc::ccccccccccccccccccccccccc::cc::c::::::c:::::ccccccccccccccc:::cccccccccccccclllcccllcccccccccccccclccccc    //
//    ;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;;:::;;;;;;;;;;;;;;;;;;::;;::::::;;::;;;;;;::::;;;::::::::::::::c:::::::::::::::::::::::::::ccc:::::::::::::::::c:lxkkkkkkkkkkxl::cccc::::ccc:::::::cc::::::::ccc:cccccccccccccccccccccccccccccccccc:::c:::::::::c:ccccc::ccccccc::::::cccccccccccccccccccccccccccccccccccccccc    //
//    ;;;;;;;::;;;:::::::;;;;;;;;;;;;:::::;;;;;;;;;;;;;;;;;;;;;;:;;;;;;:;;;;;:::::::;::::::::::::;:::;;::::::::::::::::::::::::ccloodxdcc::::::::::c:dKNNNNNNNNNNKocccc:::cc::::cdxddolc:::::::::ccc:ccccccccccc:ccccccccccccccccccccc::::cc:::::::cccccccc:::ccccccc::::cccc:cccccccccccccccccccccccccccccccccccc    //
//    ;;;;;;;;;;;;;;;::::::;;;;;;;;;;;:::;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::::::::;::::::::::::::::::::::cdkOO0KXXNNKd:::::::::::::dKNNNNNNNNNNKocc:::::::::;:dXNNXXK0Okxoc:::ccccccccccc:::cccccccccccccccccccccccc:::::::c::::::cc::ccc::c:::ccc:cc:::cccccccccccccccccccccccccccccccccccccccc    //
//    ;;;;;;;;;;;;;;;;:::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::;;;;;;;;;::;:::::;;;:::::::::::;;;:::::::::::::::::::::lONNNNNNNNNNOl:::::::::c::dKNNNNNNNNNN0o:::::::::::;l0NNNNNNNNNNOc::::::c:ccc::::::cccccccccccccccccccccccccc:::::::::::::cc:::::ccccc::::::::::ccccccccccccccccccccccccccccccccccccccc    //
//    ;;;;;;;;;;;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;;;;;:::;;;:;:::;::::;;::::;;;:::;;::;;::::::::::::::::::::::::cxXNNNNNNNNNKd::::::::cc::dXNNNNNNNNNNKo::::::::::::xXNNNNNNNNNKd::::c:ccccccccccc::ccccccccccccc:ccccccccccc::cccc::::::::ccc:::ccc:::::::::cccccccccccc::cccccccccccccccccccccccccccc    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;;;;;;;;;::::::;;;;;;:::::::;;;;;;:::::::::;;;;;;:::::::;;;;;::::ccodo::::::::::::::lONNNNNNNNNNOl:;;::::::::dXNNNNNNNNNNKo:::::::::::o0NNNNNNNNNNkc::::::cccc:::cdxocc::cc:ccccccc:::cc:ccccccccccccc::::::::cccc::::::::::cccccccccccccccccccccccccccccccccccccllccccccc    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;::;;;;;;;;;;:::;;;;;::::::::;;;;;;:;::;;:::;;:::::::::::::::::coxOKXNKd:::::::::::::cdXNNNNNNNNNXd:::::::::::dKNNNNNNNNNN0o::c:::::ccckXNNNNNNNNNKo::::c::cccccclkXNX0Oxolc::cccccccccccccccccccccccccc:::::ccc::::::::::ccccccccc:cc:::::c::ccc:ccccccccccccccccccccccccc    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;,,;;;;;::::;;;;;;;;;;;;::;;;;;;::;;::::;;;;;;;;:;;::;;::;:::;;:::::::ldOKXNNNNNNXxc::::::::::::lONNNNNNNNNNOl::::::::::dKNNNNNNNNNNKo::::::::ccdKNNNNNNNNNXkc::cccccccccclOXNNNNNNX0kdlccccccccccccccccc:ccccc:cc::::::::::::::cccc::::c::::::::::::::ccccccccccccccccclllccccccclcc    //
//    ,;;;;;;;;;;;;;;;;;;;;;;;;;;;,;;;;:;;;;;;;;;;;;;;:::::;;;;;;;;;;;;;;;;;;;;;;:;;;;::::::::;::;:oKNNNNNNNNNNXkc::::::::::::dKNNNNNNNNNXxc:::::::::dKNNNNNNNNNNKo:::c:::::ckXNNNNNNNNN0o::ccccc::cccoONNNNNNNNNNN0occcccccccccccccccc:cccccc:::::::::cc::::::c::::cc::::::::::cc::ccccccccccccccccllllccccccllll    //
//    ,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;;;;;;;;;;;;:;::::;;;;;;;;;;;;;;;;;;;;;;;::::;;::;:::;;;;;:o0NNNNNNNNNNNOl::;::::::::lONNNNNNNNNN0l:::::::::dKNNNNNNNNNNKo::::::::cdKNNNNNNNNNXkc:cccc:::::cd0NNNNNNNNNNN0oc:cccccccccccccccccccccccc:::::::::::::::::::::::::::::::::ccccccccccccccccccccccccccccccccccl    //
//    ;;;;;;;;;;;;;;;;;;;;;;;,;;;;;;;;;;;;;;;;;;;;;;;::;;;:;;;;;;;;;;;;;;;;;;:;;;;;;:::;;;;;;:::::;;:lONNNNNNNNNNN0o:::::::::::dKNNNNNNNNNXx:;:::::::dKNNNNNNNNNN0o::::::::ckNNNNNNNNNN0l:::cc::c::cdKNNNNNNNNNNXOl:::::ccc:ccccccccc:cccc::cc::c:c::::::;::::::::::::::::::::cccccccccccccccccccccccllccccccccccc    //
//    ;;;;;;;;;;;;;;;;;;;;;;;,,,,,;;;::;;;;;;;;,;;;;;:::;:::;;;;;;;;;;;;;;;;;;;;;;;;:;;::;;;;;::::::;:lOXNNNNNNNNNNKdc:::::::::ckNNNNNNNNNN0l;:::::::dXNNNNNNNNNN0o::::::ccdKNNNNNNNNNXx::::::::c:cxKNNNNNNNNNNXklc::::ccccccccccccccccccccccccccc::::::::::::::::::::::::::::::ccc:ccccccccccccccccclcccccccccccc    //
//    ;;;;;;;;;::;;;;;;;;;;;;;,;;,;;;;;;;;;;:;;;;;;;;;;;;:::;;;;;;;;;;;;;;;;;;;;::::cooc:;::;;;;;;;;;;;ckXNNNNNNNNNNKdc::::::::co0NNNNNNNNNXkc:::::::dKNNNNNNNNNN0o:c:::::lONNNNNNNNNN0l::::::ccclkXNNNNNNNNNNKxlcc::::::::cccccldxlcccc::::cccccc:::::::::::::::::::::::::c:::ccccccccccccccccccccccccccccccccccc    //
//    ;;;;;;;;;;;;;;;;,;;;;;;;;;;;;;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;:;;;:lkKXX0dc:;::;::::::;;;cxXNNNNNNNNNNXxc::::::::ckXNNNNNNNNNKo:::::::dKNNNNNNNNNN0o:::::::dKNNNNNNNNNXxc:c::::::lOXNNNNNNNNNNKdc:::::::::::ccclx0XX0xocccccc::::::::::::::::::::::::::::::ccccccccccc::cccccccccllcccccccccccccccc    //
//    ;;;;;;;;;;;;;;;;;,;;;;;;;;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;;;;;;;;;:::;;::;;:coOKNNNNNX0dc::;;:::::::;;:dKNNNNNNNNNNXkl::::::::o0NNNNNNNNNXkc::::::dKNNNNNNNNNN0o:::c::lONNNNNNNNNNOl:::c::::oONNNNNNNNNNN0dcc:::c:cccc::clxKNNNNNNKOoc:ccc:::::::::::::::;;;;::::::::::c:::ccccccccccccccccccccccccccccccccc:cc    //
//    ,;;;;;;;;;;;;;;;,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::cdOXNNNNNNNNNX0dc;:::::::;;;;:o0NNNNNNNNNNXOo:::::;:cxXNNNNNNNNNKo::::::dKNNNNNNNNNN0o::::::dKNNNNNNNNNKd::::::::o0NNNNNNNNNNN0oc:::::::cc:cclx0NNNNNNNNNNXOdc:::;;;:::::::;;:;;;;::::::::::cc::::c:ccccccccccccccccccccccccccccccccc    //
//    ;;;;;;;;;;;;;;;,,,;;;;;;;;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::;cxKNNNNNNNNNNNNX0d:::;;;:::::::o0NNNNNNNNNNN0o:::::;:l0NNNNNNNNNNkc:::::dKNNNNNNNNNN0o:::::lONNNNNNNNNNOc::::::cd0NNNNNNNNNNXOoc:::::::ccc:lxKNNNNNNNNNNNNNKxc:::::::::::::::::::;::::::::ccccc::ccccccccc::cccccccccc:::ccc:ccc:cccc    //
//    ;;,,,;;;;;;;;;,;;;;;;;;;;;;;;;;::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::;:lkKNNNNNNNNNNNNXOdc:;;:::::;;:lOXNNNNNNNNNN0o:::::::xXNNNNNNNNNKd:::::dKNNNNNNNNNN0o::::cxXNNNNNNNNNKd::::::cdKNNNNNNNNNNXkl:::::c:::cclx0NNNNNNNNNNNNNKkoc:::::::::::::;:::::::::::::::ccccc::cc:cc::::::cccccccc::cccccc:cccccccc    //
//    ;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;;;:;;lkKNNNNNNNNNNNNX0dc:;;::::::;ckXNNNNNNNNNNKd::::;:lONNNNNNNNNNOl::::dKNNNNNNNNNNKo::::o0NNNNNNNNNNkc:::::cxXNNNNNNNNNNXkc::::::::::lx0NNNNNNNNNNNNNKklc:::::cc:::cc::::::cc::::::::ccccccccc:::::::c:::::::c:::ccc:cccccccccccccc    //
//    ;;;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;;;:;;;;;;;;;:;;;:;;;;;:;;;;;;;;;;;;::;;;::;;:lxKNNNNNNNNNNNNX0dc;::::::;;cxXNNNNNNNNNNKx:;::::dXNNNNNNNNNXd::::dKNNNNNNNNNN0o:::cxXNNNNNNNNNKocc:c:ckXNNNNNNNNNNKxc:::::::::lx0NNNNNNNNNNNNNKklc:c:::::cc::::cc:ccccccc:::cc:ccc::cc:ccc::::::c:::::::::::::c:cccccccccccccc    //
//    ,,;,;;,;;;;;;;;;;;;;;;;;,,,,;;;;;;;;;;;;;;,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;lkKNNNNNNNNNNNNX0dc:::::;;;:dKNNNNNNNNNNXkc::::cONNNNNNNNNNOl:::dKNNNNNNNNNN0o:::l0NNNNNNNNNXkc:::clOXNNNNNNNNNNKd:::::c:::cx0NNNNNNNNNNNNNKkocccccc:ccccccc:::c:::ccccc::cccccc:cccccccccc:::cc::c:::::::::cc::ccccc:::ccccc    //
//    ,,,,,,,,,;;;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:lkKNNNNNNNNNNNNXOdc::;;;:;:dKNNNNNNNNNNXkc;:::dKNNNNNNNNNXxc::dKNNNNNNNNNN0o::ckXNNNNNNNNNKo::::oONNNNNNNNNNN0dc:::::cclx0NNNNNNNNNNNNNKkoccccccccccc:::cc:ccc::::ccc:ccc::cc:::c:::cc:ccc::::::::::::::cccc:::::cccc:::ccc    //
//    ,,,,,,,,,;;;;;;;;;;;;;;;;,,;;;;;;;;;;;;;;;;;,;;;;;;;;;;;;;;lxxoc;;;;;;;;;;;;;;;;;;:lkKNNNNNNNNNNNNXOdc:;:::;:o0NNNNNNNNNNXOl:;:ckNNNNNNNNNNOl::dKNNNNNNNNNN0o::oKNNNNNNNNNXkc:::o0NNNNNNNNNNNOocc:::::lx0NNNNNNNNNNNNNKkoc:cccc:cccc:c:::::cldkkl::cc::c:::ccc::::::::cc:cc:::ccc::::ccc:cc::::::::cccc::ccc    //
//    ,,,,,,,,;,,,,,,;;;;;;;;;;,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;,;:dKNNX0kdc;,;;;;;;;;;;;;;;;;lkKNNNNNNNNNNNNX0dc:;;;;;lONNNNNNNNNNN0o:;;oKNNNNNNNNNXx::dKNNNNNNNNNNKo:ckXNNNNNNNNN0o::cdKNNNNNNNNNNXOl:::::clx0NNNNNNNNNNNNNKkl::::cc:cc::c::c::coxOKNNN0o::::::::::::ccc:::::cccc:::::c::::cccc::cccccc:cccccc:::::    //
//    ;;,,,,,,,;;;;,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,;ckXNNNNNNNKOxl::;;;;;;;;;;;;;;:lkKNNNNNNNNNNNNX0dc;;;;;cOXNNNNNNNNNN0o:;ckNNNNNNNNNN0l:dKNNNNNNNNNNKo:dKNNNNNNNNNXxc:cxKNNNNNNNNNNXkl:::cclxKNNNNNNNNNNNNNKkoc:::::::c::::::cldk0XNNNNNNNXkl::::;;:::::cc:cc:cccccccc::::::cccccccc::cccccccccccc:::    //
//    ,;;;,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;o0NNNNNNNNNNNNX0kdc:;;;;;;;;;;;;;:lkKNNNNNNNNNNNNX0dc::::ckXNNNNNNNNNNKd::oKNNNNNNNNNXxcdKNNNNNNNNNN0olONNNNNNNNNN0o:lkXNNNNNNNNNNKxc::::lxKXNNNNNNNNNNNNKkl::cc::cc::::::coxOKNNNNNNNNNNNNN0oc::;::::::cccccc:cccccccc:::ccc:::ccc::cc:::ccccc::::::    //
//    ,;;;;,,,,;;;;;;;;;;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;o0NNNNNNNNNNNNNNNNNKOxoc;;;;;;;;;;;;;lkKNNNNNNNNNNNNX0dc:::cxXNNNNNNNNNNXxc:kXNNNNNNNNN0odKNNNNNNNNNN0odKNNNNNNNNNXx:ckXNNNNNNNNNNKdc:::lx0NNNNNNNNNNNNNKklc::::::::cc:cldk0XNNNNNNNNNNNNNNNNN0o:::::::::ccccccccccccccc:::cc::::::c::c:::ccccccccccc:    //
//    ,;;;;;,,,;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:lxOKNNNNNNNNNNNNNNNNNX0kol:;;;;;;;;;;:lkKNNNNNNNNNNNNX0dc:;:dKNNNNNNNNNNXkcl0NNNNNNNNNXkxKNNNNNNNNNN0dONNNNNNNNNNOllOXNNNNNNNNNN0d:::lx0XNNNNNNNNNNNNKkoccc::::::::coxOKXNNNNNNNNNNNNNNNNNKOxoc:::::::::ccccccccccccccccccc:::::::::cc:::::cccccccccc    //
//    ,;;;;,,,;;,,,;;;;;;;;;;;;;;,;;;;;;;;;;,,;;;;;;;;;;;;;,,,,;cdkKXNNNNNNNNNNNNNNNNNKOdl:;;;;;;;;;:lkKNNNNNNNNNNNNX0dc::o0NNNNNNNNNNNOoxXNNNNNNNNNKOKNNNNNNNNNNKOXNNNNNNNNNXdo0NNNNNNNNNNN0o::cx0NNNNNNNNNNNNNKxlc::::::::cldk0XNNNNNNNNNNNNNNNNNX0kdl:::::cc::::::::cccccccccccccc:::::::::::ccccc::::cccc::::c    //
//    ;;;;;,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,;;;;coxOXNNNNNNNNNNNNNNNNNX0koc;;;;;;;;:lkKNNNNNNNNNNNNX0dc:l0NNNNNNNNNNN0x0NNNNNNNNNNXNNNNNNNNNNNNNNNNNNNNNNNOx0NNNNNNNNNNXOl:lx0NNNNNNNNNNNNNKxl::::::::coxOKXNNNNNNNNNNNNNNNNNK0koc::::cccccc::::c::::c::ccc:cccc:cccccc:::::ccc::cccc:ccccc::::    //
//    ;;;;;,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:ldkKXNNNNNNNNNNNNNNNNNKOdlc:;;;;;;lkKNNNNNNNNNNNNX0dclOXNNNNNNNNNNKKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKKNNNNNNNNNNXkllx0NNNNNNNNNNNNNKkl:::;:::lox0XNNNNNNNNNNNNNNNNNX0Oxoccc:::::cccccc::::c::::::ccc::::::::cccccc::::cc::cc::::cc:::::::    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cox0XNNNNNNNNNNNNNNNNNX0koc:;;;;;lkKNNNNNNNNNNNNX0dokXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXxox0NNNNNNNNNNNNNKkoc::::cldkKXNNNNNNNNNNNNNNNNNKOxoc::::::c:::::cc:::::::::::::::::::cc:::::::cc::cc:::ccccc::::::::::::    //
//    ;;;;;;,,,;;,;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:ldkKXNNNNNNNNNNNNNNNNNKOdl:;;;:lkKNNNNNNNNNNNNX0xOXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKkk0NNNNNNNNNNNNNKklc:::loxOKNNNNNNNNNNNNNNNNNXKOxoc:::::::::::::::::cc:::::::::::::c::::::::::::c:::c::::::cc::::::c::::::    //
//    ;;;;,;,,,,,,,;;;;;;;;;;;;;;;;;,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;cok0XNNNNNNNNNNNNNNNNNX0xoc:;:lkKNNNNNNNNNNNNXKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKKNNNNNNNNNNNNNKxl::cldk0XNNNNNNNNNNNNNNNNNX0kdlccc:::::::::::::::;::cccc:::::::::::::::::::c::cc::::::::::::::::cc::::::::    //
//    ;;;;,,;;;;;;,,;;;;;;;;;;;;;;,,;;,,;;;;;;;;;,;,,;;;;;;;;;;;;;;;;,,;;;;,;;;;;;;;:ldOKXNNNNNNNNNNNNNNNNXKkdl::lkKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKxl:coxOKNNNNNNNNNNNNNNNNNXKOdlc::::::::::::c:ccc:::::;::cloodxdc:::::::cc:::::c:::c:::::::c::::::::ccc:::::::    //
//    ;;;;;,,;,,,;;;;;;;;;;;,,,;;;;;;;,;;;;;;;;;;;;,,;;;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;;;;cok0XNNNNNNNNNNNNNNNNNXOxoclkKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKxlldk0XNNNNNNNNNNNNNNNNNX0kol:::::::::::::::::::::cclodxkO0KXN                                                     //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZEN is ERC721Creator {
    constructor() ERC721Creator("Zen Bird", "ZEN") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
library StorageSlot {
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