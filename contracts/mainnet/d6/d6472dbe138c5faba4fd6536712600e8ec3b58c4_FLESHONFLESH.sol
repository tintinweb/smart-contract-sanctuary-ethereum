// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FLESH ON FLESH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//    uvJYuJjsusJsJs1JJJ1susuJuJuJuJjJuJuJuJjJ25KXKXPPdPPKKXPPbdEPPEQQMgDEDEgdbK5JuJjsuJjJXEuKLLjJuJusjsjjuJuJjJjssY2IjjUu11IuUUUUUj12UY    //
//    YvvYYYLYLsLJYssJsJsusjJjJujuJjjjJusuJuJjYU1IUIIKKPX5UKKqr2ZbU```vREZD5::J5juJujuJuJJsgKq1vYjYsYjsujuJjJuJjYY1KSJYsYJYjsJsjYJsJJuLv    //
//    YrYYssJYsJjsjsjJjJujjjjsjJjjuJjjuJuJjJusu155SSKKPPb2IK5````jX7-``JQM:````r2uuJjJjJJsY1QQBuLvJgjsjJjJuJusJvL2gM2vjJuj1uUuUu11112u2s    //
//    sLYJYJsjJjsujJJujuJuJjJuJuJuJuJuJujuJujusU252KKPKPKKIK``````:2j-`-BE````i7UUjusjssLsvJZBQBS77B1ssusjJuYY7uKMggK5juJ1uUuUj1u1j1J1uj    //
//    LvjYjJuJuJuJusuJusjJuJuJuJjJusjJujuJuJuJjjU2S5KSS221Kv``````-:Ki-`bi```Jj`2j1JjjqPUsIsdQQQBbLRR7YsjJsLL7XQBMQQE2jjuu1j1u1u1u1jU11s    //
//    sYJ1JuJuJuJusuJjJjJjJuJjjjJujuJjJjsujuJuJ1j21I1UJJsI1`````:``iLI:`````rdUru1juJubBQdEbPMRQQBQQRKvLLYvj5RBBERQP2sJ1u1j1JUjuuUuUj1js    //
//    uv1J1jjJ1j1JujuJuJuJuJjJusjjuJjJjJuJusjsjsUU55XSXIIX-``:--````:7L:-``-XIUuujuJjsYvXQQZdgMgQRQQRMR1v1dgBQQDEQQ2Ysjjuu1jUu1j1u1uuuUY    //
//    usu1juu1j1JuJusjJuJuJuJusuJjJjJujjjuJuJusju22XSX5SUr```v2r`````:r:```sK5uUu1jujjY2PDgBEgDMgMgQQBQQDRQQZQgbRBMjL1j1j1uUjUj1uUj1u1uJ    //
//    UYUjuu1juj1j1juJusuJuJususjsjsJJuJuJuJuJusuUXSqXXXd:-`jPEdPs:``:````idX5S5SI5II11JjXbQQEDgQggMQRQQBQQgQM2dMQXvsJuJuJUJUjUj11Uu1u2s    //
//    1JuUuUjuuujuJ1JuJujuJjsjsJYYvLLYLJsusjsuJUU5K57sPRS-Y55qu1UqP7iM7```IPr-:r75UvvU1uJ2MRQQgMQQMRMQQQRRgQgKgQMgKjYYLsYJJ1J1sjjU1UuU1J    //
//    2s2uU1UuUJ1j1jujujusJssLLL1ISSSjYvYYJsjJ11IJ:```````i--jUJ1Jui`dPi:-KU``````````rJs1gMQMRMQRRQRDZDMgRgDMBQZMbLJ1KI2qUjjs252uU11jUs    //
//    Uj1UuUu1u111uuj1JussvvuqXRQBBBBBRE1LvssjjI:`:J1ji````::JUuj2rv7vY7:iqbKXI7```rSYYj1gEggRgQgRMQMMdDgQgMgQMRggbZDBBBgPJIPDZPuuj1Juuj    //
//    Is21U1UuUu1j1JujusLvKMBQRMQMQMQQBBBQbYLY1u-`rXMREI-``SvJIjUI:```:-:UXIXXZX```dE2usZEKUUPMRQgQMQMQRQMQMRgRMQDMbDEMgZdQBBMZIJuUJuuUJ    //
//    UuU21UuUuUu1jujuLLXQQQRgEMMQMQDgRBMBBBSLJs-:vIggXD5:SP:uq52b7```:ii5SKSXqS``-X1uY5b2jU2KPDRBQQRQMRMRRQgMgQQRgDEgbQQBDESUj1uUu1u2Uj    //
//    2j2U2u2u111u1J1LYZBMgQQgMMMgMRMZRRQQQQBSLs```sDBBBBBI```5qbS:`-ir:-```-:rY``-I2JJKXISSX2jLjPQQBQQMRMQMMgQMMDRRQggZbuv7vvssjj11I12Y    //
//    2122121UuUjUjuYuMBgQRQgQQQRQRRRQMRgQMRQBI25:```7j:``-`````````rYrLs7:-``:L```U1J1KKqqPXS5v--LEQBQQQQRQMQQQbDMMMQQRPqKPqXUUuuu5S2uu    //
//    SjIu21U12uUu1jLbBgRRQMQMQQQRQRQMRgQRQMRQBDPuY-`````:2Iu:::i:7UIiXdgdPqqsrSL``JujXKPKSIIIb27-`-5dgBBQQQQQQqPEQEKgBBBBBBBBBBQPu--j2Y    //
//    21UIU21U12u1u1sbQQRQMRMQMRQQMQgQMQRQMQMQQBPjKPJ::jbBJUjXSPPbqS7-KPqPXKUU`2EPU1s5SqKX21s17Li2U--7YdPgBBQgKsZQMRdEEEKS12U2uIUIUJv1Uj    //
//    Ij21212121UuUjXgBRQQQRQMDgQRRgQMQMRRQMQRQQBPKMBi`-YgBSS2qS5IqXS2bqPKqXS2:s1j1s2PEKPuvv:ir-`:Pb````-7U1uKP5bEDdDPJvYLsYJJuJjjUUI12s    //
//    IU252IU212jUuJbERBRMgBQQDgMQMQQBBBQMRBQQMQQQbBBI`7DMB5uqKPXqKEPXqdqPXK5SU2sJYJXKPZUq7i-`-```-`-XSj``````Y5IXKMgsLju2uUu2J112UUU2Uj    //
//    SjIUIUIuI121u1gEgQQZXQBQQgQQBBBRPPDXdMBRQMQRRRBBgQBBQQP5q5qKbPdqXPdqP5S21Yvvv1PjPBKdBj`````````:Jj`7r:````iSEPBSj1U121UU21U121212s    //
//    51U2U2UIU2U2JXEBZEbMrLQBBBBBQZ1JLJj2IggQQQMQRRRQBBQQRBBK2XqbPEbEKKbPKK21JIXDEKPUvBQu:SI```````````````````idPuS5jUuUU2uUuU121Uu21u    //
//    Su522UIUUUUjUKKZBMQBZ`7dQQPrv7r7USdDBDXEQRRMQgRQQgMRQMQIJuKKPbEdd5PPP51qQQBBDSbj`iDZvSBX:-```````````````-bKuJuu11U121U1U1212u2u2L    //
//    IUII2I222I1U155qQRQQYr---iirvsJPZgBBZI2dBQRQRQgQRQggDMQPJ2SPbEbEbqSbK5PBQQQBZKI7```iKBBQr-``````````````7gX11112U21IUI12UU1211JUus    //
//    S1I25UIU2U212uX1BQQQJ7v77rr7U2gBBbDXsu5PBQQRQMRgRRQgRMBd25PPZEDZgbSqqPBQQRQQQXv```vPRQQ```gQXgdi``````iSb5212U2U2U21U12U2121Iujj2L    //
//    IUI525I5UI1I1221RBQBBBMBQBQ5rubRg5jsv2IEQQMQMQQQZMQQMQQEUqXPPZZgdPI5KMBBQRgQBP`sgBBBRQ-```bBQI-QBi``-12QSuu21U1IU22U1I121UU2U2uujs    //
//    SUS2I2IU5U212uUKBRQMQBZ7XSbD::5SqIujU1SQBMQMMgQRgMQQBQBdIXX2UIqqdddISYXMBQBBBQjZDDDgM``````7Zqsv-``uBBK-EDjJ212U2UI12U2U21211uUjjv    //
//    525525I52I2IU1uMQQMRRQBK:irsJisPKEUsuUPBQRgMRMgQDgKbEQBMUUdRPXqbPZEbYiYbQBBBL`PgP5qP````5E```````:1gBRBI:vQKsUU22I22I51I121UJ1jjJL    //
//    S1SIS5525IIU2u2gBRQMRRBBgvr7u77UK5IKbSQBQRQZQMMgQQgIjvjEQKBBBDPdEPPgSruSZv````BbuS5s`````D`````:MB`2BgQBdsBZbu22I252I12U21211sjJjv    //
//    XI5SIS2S2525UUudBQMMMQRQBBMPYrr11dQMKqMBRQQdgMDMgQBQgEIuZBBgQBbddEPBBQsjK````:BB27--```:7Y-`rSQBBB7BMMMQQB1dQDJ2II252I12U2u1uJJJLv    //
//    K2X55I5IS25IIUuUMQRMMMQRQQBBBQdSKPq2LYQBQQQDggRgggRQQDgu7EBPMDZPbPbQBBQbg````ZBQBQdvvI2vYYKQBBBQB2QBgMRRQDPEQQZj5IS2I2UU2juj1JjjJr    //
//    5I5K5XISISU525u1PBQQgRMQRQMQQBBBbUUPsIMMQQQRMQMMMQEDMQdP`:QREBgDqPPRdBduXK```BBQRBBQZZgMZQBBBBQR`:MRDBRMgRMMgQQduS5512u11jJuJjssLr    //
//    KUK5X5XI5IS2IU2jPQQQQMQgQRRMQQQgREQBJ-MIBQQMRgRREDQgQgBg1`uQEMgZP5gBvSMggE``DBBRMRQQBBBBQBBQQMdKiMbgQQgEQgQDEEQQbUSIIU2JuJuJJYYvYr    //
//    XSSX5X5SIS2555UUKQgBMQRRRQMRRQQPME:i``2UQQRQgRDQgMMQQRgBQJ:DdggEEqgBSUBBQB``MBQBMQgMMQQBQBRgdRDdDKSQRQEMQgZggbgQd5II2Ujuj1sJLYYsJ7    //
//    qIXXXSKSX5XIS2I1UEQMZRQRQRQQQQQEdj`````rbDBMQMggQQRgQQbEBBusQMQPPPRQBYvBBBrsQPqRBMQRQQBgDbEEgQBgSvbQBgEgBgEgQEDDb25UUJjJjssLLvY7Jr    //
//    KXSKSKSS5SIXI522UdMBdQQQMRMQRQRXrr:-````UQQRMQMQMQQggBQgsQQKBPBBMQQBBZ``BBuJgE1gZRRMMBMEPEggRQggQEPQQgEQQZZBZEEMKI21JsYsLsLsvYLYYr    //
//    qIqXX5XSK5XSS5XUUPBQRMQRQgRRQQQJ7PBQBM``DBQQQRRRRMBDuMBRDsQBQPZDEMRQBB2`EBLjQ51PgIXqMgPdEDMgQMZDRMgMQPgBMXQQPdQDKI2uJvYvv7vvvvv77i    //
//    KSSqSKSKXKXKSX55U5RBZgRQRQRQQQZbrgBBBB``BBQQgQRQgDgBPuQRgdrRg27uvIrdQBBBB2rPg1bM5KZBREdgEgZQREZggMgBEXQBXbBbPRBduS1jvYr7rr777vv77i    //
//    P5KXKXKSK5XXXSXISJPBDEQMQMQMQQZK2rXBu``iEBMQSSRgMQbqB7`RMBriPdgqjjBQRRQBQs1D5vUKXQg2KbZDEZQQZdggggQZSEBZqQZPMB:`PUJYL77rrr7rr7v77i    //
//    XSKKXKXKXKSKXK5XI2IBKJPMQQMQMQgqXJ7`````rEBBgrdQdBBXDI``QBP`gZrLvbgBQQgB2qQgvUBKPddKdEDgERQgPggggMgPqBQEZQggRZ``PUv7rrrrrr77rrr77i    //
//    qIPXKKqSKXKXKXK5XI2gP11dQQRRQZdbZ1U2````-QggB2vdKQB7vB1``-r`IBI1vXMBQgQD2JMD12KIEKsIgZgEMMMPEgMggEDdMBZMBQEMdK2517r::riirr7rrir7v:    //
//    KXXPKPXqXqSKSKSKSX2PKSI2gBRRQR2gIu2EP```dSLZBBDP1BdrsRB1`````BBBBL`2QBMdERQMPb`7u1PgdZggMRddDMZREbgDMMDQEZQBuP21viir:ir7rrrrr7r7vi    //
//    q5qKKKqKqSqXqSKSX5XSK2SvKBQRQBMEDrv1Ij`dP``-KQBK`B`uQEDQBDP:sBBgMXrXMBbddQQDgP25LDBgEDgQBgggQQQDZMRdgDMbdQP-``SJ7iiirirrrrv777rrL:    //
//    XXqqKKXKKqKqSKXKSKSKS5IKdBQQMQQXI``:7:sMurr77QBQ`QrXEdbQM7``BBE2vL7rPBKMDDqgPqQXbQBZZMRBQBBBBQdgbQgdZQggQI```:Xvii:rrriiirr777ir7i    //
//    P5PKqKKXqKqXK5KXKSXSK5S5PZQQQDPEdJ:`-YKY::i-`i`````PBMb7```XBBQggPK2gS5BgZPbDMMbiiQbDQB``Li-``IgMMgRBBBQq7MEUKsr7iri7rririrr7r7r7:    //
//    KSKqKKXPXqXqSK5KSXSKSX5I2PbgQM1PQMPS11uu`````````sBBP7`````5dBQQggQBB5EBEDEqJ2ZgsKgEMBKib````MBQERRQMZbgBB`XqUv7v7r7r7vir7r7rv777i    //
//    qIKXKXKXKXXSXIX5XSXS5IX222dbDMquI1KSX5Iqb-`````PBBX``````:-IsQQMgDRMBXPBQEDSuXUSZBgDBR``s-``SBI7PMDDgbMBBDSEPqqSK1JUUIKjUUU1522Iqs    //
//    KSSKXPXKSKXKSK55ISI52X552USZdZdXIv7Y71gBBBBBBBB2-`````````BBsZBBQQQBQbPZQBMQdgEUPQdMgDIBBBBBr`7BBQMRMMZR2````````-````````````````    //
//    P5qXKSqSKSK5SSX552S2IISU52uKgdbqqsr1PSEQRDZdK-`````````````QQIXgQMMbdPZqKQBQb2ESMggDMQBBBBBBsEBBBQQRRDQ5``````````````````````````    //
//    PKXXS52XIXISIIUI2IU12SSSI52JPgEbSX7Sg:```:`````````````````2qDS2IdqPPEbEKbQQMdKPQDDQBBQBbqDiMBBQMMgEEEQ2``````:-``````````````````    //
//    21bXKSXSXSX5SI52SIS52jsuXJu1vSEEbPXjKr`````````Y5Kr``````BdJsJKgPuu2PEEdgZMQQQBBQZgP``````:YBQQggggbbKQb:```RBBB-`````````````````    //
//    uLMBQQQQgMgMZgggEZqZX7``Pu7D7SqbbZbqUPr``````-P2-```````QEqUJ22XKP2UKDgQQDgRMgqQQEZI`5Y`IDBBQBQgEgdZdPgRgDEQgggdPBBBBBBBBBBBBBBBBB    //
//    gs`RBQBRRgRgMZgZDZZdMgMYsbKEZPqXKPREEEMRPi``1MQBBBU``-KBBKKS5SPXKbBQBQgDZMQMQDqqgEggMBBBQBBQQggdZbdbDZIUbdEgMXEQQDZKPPQRggRRQRQQQR    //
//    J2r2qEMBBQQDDMMgdZdZdggP2gZDPPKP5bPEKPbgMBQEDgEEQBBBBBBBBdSPKPqPPEQQPbbQMQQQbddEPDKbdZZDPdgMZgddPbdK5EbS2dZPdMEQQgPbX2UdPPPbPPPbbE    //
//    qEgK121jUSX7SjbBQggZgZgEZZEEEddPvSDbbPEEEdd2PPEPRQZBgQQQQqPPPPbPdPgMQQQQQRRRP2KIqqPKPEZbEPPqbbdqbPgdU`````iZqdPPgDdQQ2sXqSX2XXqqEP    //
//    bBs`7-``1SKq5sJBBBBBBBBBBBQQgMDZEdPDEZEZdgq2KPbEgBMQQQMQQdPdqbPbPdPdZDbZDMgRQP5PPMqSXDEEddPPqdPqqPEg```````bBg5IJXgRQP722XSX5PPbKK    //
//    `r``diDdgQgDBZU```I```u`:ZPKQBBBBBRZEPbPPdbUqqggDDMgggRQQPEdZbdbPPdbEbEZgZRQBZ5UX1JL5ZZdEEgDZqbPPPQU````````LQKbK:UMbb-:LJ225SX111    //
//    `v:-BQKKPKXPPK```````````````````LdQBBBBEEqUXbgMDPPqPZbDgEbEZEPdPEPEZMZgDRQBQgEZDXuSXQBBBBBBBBDZggB:```-``````gB-``IBM7```-L7rYuJ1    //
//    :2BSKdjj7bE-5u`````````````````````````-qdbSKbRRBREPZEdDQDZEZbEdEPPPgQBBBBBBBBBBBsrrvPgDgq2bMBggBBBB:`````````b````5BBQ-``````-ir:    //
//    LPKDXPQdMBj`MK````````````````-`````````uQbdgQBBBEgDqbERggDgggEddEPPZBBBBB2i:i-```-````````````````ZB`````````1```-PBBB2``````````    //
//    vvBBdQD2bKr7QK````````````:PZBg``:`````7BBBB:BBv```ZQ5XbPjdPPbKqbgKj51Ps```````````-:`````````````````````````iSvrP2E2````````````    //
//    b5QBgP:EUr:gQR```-E``````7QDSZQMbd-````BB:`r``P`````BgbRSvv1r1sv7Uvriv1PPi``7``````:`````````````````RE:`````r5RP``ju`````````````    //
//    BMQMEK-IMi`jMQX2BBQbZ``````````1KJ:``2BBP``E````````rBDRQEDqjSX21rijd7SDQQ``-i`-r```````````````````b`2``-``PbQBj``:``````````````    //
//    gMBEDZgBB``gPb`````:u-```````````-```BBBB````````````iBdMEERdgQq``:5I7qXKB-``--````````````````````````Ej``KRBBK-````````:::--````    //
//    QBESBUrBB``KBg``````s-``````````````BBY`````````````BQQgPPbBQZRP``iKJrUbgMgs2QM5JDI````:````````````BB``B7rBRdK:`````````:iiri:```    //
//    DBb5BEKZI```RB``i```-``````````````5BBE```````````j-`BddPMZBQRZgMD5BBBbDBBQBQQQBBMdRBB2P```````````KR```-BKgK`QR:`````````-irrii-`    //
//    MQg5QQXDq```2g`````````````````````IBB`````````````QqjBSEDQQRRBBBBBBBDgQPY77JUKdP2SDRBB71``:MP`````````d`USvBvRBK```i`-:-:ri--i7r`    //
//    QBBRZgdBBq`````````````````````````QBP````````````uRBEDdbgBBDBBBBBBBQBBBDQdj7Y77r7vY1EBXr```-DP`iERQi``gqK-`D1II```--`--:r7Yvr:-i-    //
//    IgBBQRZZBd````````````````````````UEBg````````````BBQBbqbggQRgBBBBBBBQBBqqdbU`vsLsjsY72RBK```:Mr:rMQ``5qDEP-srI``r`v``-7qii:11I7--    //
//    :rMBBBgMQBi``````````````````````QB``````````````BBBZQQqbgRR:``:qQBB:````````I1juUj:`-`-vM```````````````7qUvjPg```7```d5:i`7UUP1J    //
//    SrrMBBBQQBBB1```````````````````QBBBRgBBg55UusdBBDMQBgMgRQBd-:LL````````````5Uvr:v7iPd2YjUq```````````````-2S2:Er7`:``:q:-r`-jIE5s    //
//    BBJrZBBBQMPBBBq````````````````BBBBBBBBBBBBBBBQgPdEgEQggRgBgbBP````````````Z7PZIIPv-XSjUUXE:`````````````r``Pq`Ki`````ri`-r-`s2gIu    //
//    BBBBqbBBBEQXQQ:QBggr``````````MBQI7r:7X2IgRMQDEPbPDEdRBgQBBQM````````````````qgEQLrPDPKSSXMB````````````ui``qPiU:`````:L--r:`-ED5s    //
//    ```````sqd5--``MBqIQR7``uBBg:-`````rs````bBBJMgZEdPDDRQBQBB-`````````````````rDEb2rMQQqi``:sE````-:```:BQPE``P5v:v``:``-``ir`igq2u    //
//    `````````````````````:BBBQBBb```BBBdXBBMq-:Ms`QMZbZZggQBBB``````````````B`````:SKI2S`rv```:-rv``--``UBBBZUsisrP`jB``vv`i`-vr`SB52j    //
//    u```````````-``````7QBBK```BB7`D`-Xi````````Bq`7dDgMQQMBB``-``--``-i``PBQ```````1KDI2bi:Bg`7PDZESIJPBBBBBZXEr`LL`X1````v175U`BRSjj    //
//    qjr:ii7LUIPPqj2U21PBBI``````BB2P```Y````````sBrgZgKBBBBBB-rd`IB```:``QBgD```````PgBQM2i``DMr```XBggjUEBBZvLX``vbr`R`````````-BgXSJ    //
//    PSUJJ12X5K515PPb2XdBK````````BB2d```J```gir7EBdMgIbZqBBBBBdqjQd1Bb````BBS-```````rbESQBQ-````````vBQ5MBBQIBBP`:BDPb`````````2BP52J    //
//    Su1JUU5555uY1UIKujBBBPs``-```jBBug-LBP:gMdgEBQMQQgZr-vBBBBBBPu2DB```````-```````:7rvjui```````````:`:r2Iv`ILJ7`1i```````````QDUI2Y    //
//    Uju5SSSKSKIS5KSPJsDgQBBi-Br```EBB:``XBjBjJBBUDBQdgEbr:1YQBBBBZ:-Sr``:dbu`i``:``PZRQBbE2````:``````````````````````````i---`1BDPZKI    //
//    gDQRBQBBBQBBBBBQKvBBQBBK`Qr````:BB```1q`BQBQ1IBBSPgbPd7`7QBBBBB5UI2jBBBD:`````vgBBBPI:JXRDJJr--i-``````````````````r-`rKv`:BBEPPbY    //
//    QBQQQQMRMQMQRQgRPsXggQBB2`27````7BB```jBBBBBBZv:qur2BQXbgMPMgQBBBgKZEQQqv`jqr`IBBdXbDv```rgQBBBBBBQu:1b5`````r-EQRUPIi--LsQBgSYu2j    //
//    RgMgMgMDggMgMgMgRPPbdPDQB1rZgB-```BB`````:gBBi``RdqMQgMgbJiXBZQQBKdBBBBBBBBQBBBdg--KP-:7ivbbQgBBBBBBR15E:jBBBBQQBBBQQgZEQBBQBgI7r7    //
//    MggggggMgMgMgMgMPPbEEEbdgB1`:i`r2MBg`````-JBI``QBBQRdPZZ5usJDDgRB2XBQBQQRQgDgXPPQE7-iKd`````````````dBgirddKKbqqqdEDDQRQgMDggQBQ2:    //
//    MgMggDMgggggggggDbbPbPqPbMBI``PBBB1iX```BBq```IBQgDDggMZdDBMMBBRBjqBQMQRRMDdI7qJqbP5rubD`````````````rQ2bPPPdPbPPPEdgZMggDgZggMQBM    //
//    gggMgMgMgggMgMgMgRMgDgDdPDQBBBBBD7sbsrJQBqPS``BBEgQBBBBBBBgQgEBBBjPBMQMMgDbPU7::iKiQBRRB`````````````iXPPPPEbEbEdEEZDgDgZgZgDMgMMR    //
//    gDMgMgMDZZgdZgDDgggDggRgRgMQBBZr:2v:BBBBQD2`sBBBBQEUs7ri``````5BBPgQQRQgRddbKUr:rLI:QMQQBL`````````2BQZbPPdPdPEbZdZZgDggggMDgDMgMg    //
//    gggggMggggPEZMdggggZEEDgggMQX7r1dr`7JiKUi:`UBBQQQB5-```````````:PRBBMRgMMEqdd5U:i7vv7QDMQBQ``````gBBgZddPEbDEEEDbDEgDgDMgRgMgMgMgM    //
//    MDMgMgggMdZgMgMgMgMgMggDggQ1:L5S5:```7S7```BBQRMQQBBX---727``````ruBBQQgREPXPbI2-rvii7BMMgBB27``BBgZZPddEbdZDEgEZZggggMgMgMMMgRgMg    //
//    gRgMggZMgMMMgMgMggZMZgPEgQBj7uIP2ur-:1J-``XBQRMQMQQBBQK115Ksi-```-irSBBBQREPSPbS2-vLiisBQBBBBBE`BgZDbEbdPEPEZgZMgMMRMMgggggMgMMRgR    //
//    BMREZDgDMDMggZggDDMggZEZQBBv2Pbuvii```:2BBBMMMRMQMRRBBBZv7juIjir```-``SBBQQEbPDEKXivvrivEbgBEIg`SQZEgDMZEZggMgQMQQQMQQQRQRQRQQQgRM    //
//    PJUdQMggDgggggDMZDZggQQBBRr7SZ5::``-jQBBBBQQMRgRgMgggRQBQXrJLivSj-``````dBBBBBBBBRgUK1J11```KBBR`BMMZMggbDgQMRggDggRMQRQRQRQQBQQQQ    //
//    YrJQQgMggDMgggMDMZDZMRBBP-i22:```7gBBBQMRMMgRMRgMgMgMgMgBBBd7```--`J:````:BBBdbDBBQQdQjSE```:``i`7BZMRQMMgRgRggggMQMQRQMQMQQQQRQQR    //
//    v-rBMMggZgDEDMDDZgZgQBBJ-7Sj````7BBBQBMMgMgggRgRgRgRgRgMgQBBQ1```````````r````````````E``````````7dgDgBBBBBBQMgQQBBBBBBBBBBBBBBBBQ    //
//    J`-EBgMgMggDMgMEMDgQBDr`JXq-```uBBBQQPERQMRgRgMMRgRgMMgRQMRQBBBJ````````B```-DP```````b```````````BBBBQ`ZBBBBBBBRMBQRQBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBB2:iuXP:```DBBBBBgZQBBBBBBBSRQQQQQBQQQBRQRBBBB5````````5BQdrv-`````bs```````````srQ``````iEX2L````````-77L``-rg    //
//    PXZbPPbPdEgDMDggQQQurv2XKr``-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQi`````-Lu1````:```Qv:`jbDDP27```````````````i2KXgDqI1JUr``````    //
//    `````````````````-7LsIUui`````````````````````````--`````-````:rvK5j7SJX:````````:L:-P:`KdX55X7```````````````-`:2Yi:riii-`PBQi`:-    //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FLESHONFLESH is ERC721Creator {
    constructor() ERC721Creator("FLESH ON FLESH", "FLESHONFLESH") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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