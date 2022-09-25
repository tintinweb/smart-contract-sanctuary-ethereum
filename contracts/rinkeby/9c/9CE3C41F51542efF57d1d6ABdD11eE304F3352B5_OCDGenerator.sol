//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library OCDGenerator {
    
   
    struct OCDRands {

       uint bg1;
       uint bg2;
       uint flap;
       uint side;
       uint hole;
       uint eyecover;
       uint brws;
       uint top;
       uint eyec;
       uint brwsc;
       uint outrc;
       uint shirtc;
       uint pktc;
       string blnk;
    }

    
    function getBox(uint s) public pure returns(string memory){
             
        string[8] memory sides = [
            '',
            ' <polygon class="c7" points="357 129.25 337 145.25 337 155.25 357 139.25 357 144.75 367 126.25 357 124.75 357 129.25" />',
            '<polygon class="c7" points="343 290.25 363 274.25 363 264.25 343 280.25 343 274.75 333 293.25 343 294.75 343 290.25" />',
            '<polygon class="c7" points="355.25 280.5 355.25 255 363 248.5 363 274 367 270.5 359.25 290 351.5 283.5 355.25 280.5" />',
            '<polygon class="c7" points="344.75 139.09 344.75 164.64 337 171.05 337 145.26 333 149.01 340.75 129.55 348.5 136.03 344.75 139.09" />',
            '<polygon class="c9" points="333.63 134.62 333.63 157.52 350.08 144.55 350.08 121.65 333.63 134.62" /><polygon class="c10" points="335.33 135.65 335.33 153.83 348.39 143.53 348.39 125.35 335.33 135.65" />',
            '<path d="M358.81,127.85h0l-14.72,11.77h0c-.87.69-2,3.84-2,6.6s.91,4.27,2,3.4h0l14.72-11.77h0c.86-.69,2-3.84,2-6.6S359.77,127.08,358.81,127.85Z" />',
            '<line class="s4" x1="350" y1="171" x2="350" y2="241" /><line class="s4" x1="360" y1="164" x2="360" y2="234" /><line class="s4" x1="340" y1="178" x2="340" y2="248" />'
        ];
        
        string memory box =
            string(
                abi.encodePacked(
                    '<rect class="c2" x="125" y="130" width="200" height="200" />',
                    '<polygon class="c3" points="375 290 325 330 325 130 375 90 375 290" />',
                    sides[s]
                )
            );
        return box;
    }

    function getFlap(uint f) public pure returns(string memory){
        
          string[9] memory flaps = [
            '<polygon class="c4" points="125 130 175 90 375 90 325 130 125 130" /><line class="c5" x1="150" y1="110" x2="350" y2="110"/>',
            '<polygon class="c4" points="125 130 175 90 375 90 325 130 125 130" /><line class="c5" x1="150" y1="110" x2="350" y2="110"/><polygon class="c12" points="172.25 115 315.25 115 327.75 105 184.75 105 172.25 115" />',
            '<polygon class="c3" points="375 290 325 330 385 350 435 310 375 290" /><polygon class="c4" points="125 330 75 350 125 310 125 330" /><polygon class="c4" points="105 390 125 330 325 330 305 390 105 390" /><polygon class="c4" points="125 130 175 90 375 90 325 130 125 130" />',
            '<polygon class="c3" points="175 90 135 60 335 60 375 90 175 90" /><polygon class="s7" points="150 110 175 90 375 90 350 110 150 110" /><polygon class="c5" points="280 130 330 90 375 90 325 130 280 130" /><polygon class="c5" points="125 130 175 90 220 90 170 130 125 130" /><polygon class="c11" points="125 130 150 110 350 110 325 130 125 130" /><line class="c6" x1="125" y1="130" x2="175" y2="90" />',
            '<polygon class="c3" points="175 90 145 45 345 45 375 90 175 90" /><polygon class="c5" points="280 130 330 90 375 90 325 130 280 130" /><polygon class="c4" points="145 70 345 70 325 130 125 130 145 70" /><line class="c6" x1="325" y1="130" x2="375" y2="90" />',
            '<polygon class="c4" points="65 120 115 80 175 90 125 130 65 120" /><polygon class="c4" points="175 90 205 50 405 50 375 90 175 90" /><polygon class="c4" points="390 120 440 80 375 90 325 130 390 120" /><polygon class="s7" points="125 130 175 90 375 90 325 130 125 130" /><polygon class="c3" points="125 130 325 130 300 110 100 110 125 130" />',
            '<polyline class="c2" points="325 0 325 130 125 130 125 0" /><polyline class="c3" points="375 0 375 90 325 130 325 0" />',
            '<polygon class="s7" points="125 130 175 90 375 90 325 130 125 130" /><polygon class="c2" points="125 130 75 170 275 170 325 130 125 130" /><polygon class="c3" points="374.88 130 400 130 375 90 374.88 130" /><polygon class="c2" points="275 80 325 40 375 90 325 130 275 80" /><polygon class="c3" points="125 130 175 90 205 40 155 80 125 130" />',
            '<polygon class="c4" points="125 130 175 90 375 90 325 130 125 130" /><line class="c5" x1="150" y1="110" x2="350" y2="110" /><polygon class="c2" points="380 110 430 70 375 90 325 130 380 110" /><polygon class="c3" points="125 130 175 90 210 30 160 70 125 130" />'
        ];
        return flaps[f];
    }

    function getBrws(uint b) public pure returns(string memory){

        
        string memory lb = '<line class="b" x1="260" y1="175" x2="310" y2="175" />';
        string memory rb = '<line class="b" x1="140" y1="175" x2="190" y2="175" />';
    
        if (b==0){
           lb='';
           rb='';
        }else if (b == 1){
            lb='<line class="b" x1="260" y1="155" x2="310" y2="155" />';
        }else if (b == 2){
            rb='<line class="b" x1="140" y1="155" x2="190" y2="155" />';
        }else if (b == 3){
            lb='<line class="b" x1="260" y1="155" x2="310" y2="155" />';
            rb='<line class="b" x1="140" y1="155" x2="190" y2="155" />';
        }
        string memory brws = string(
            abi.encodePacked(
                lb,
                rb
                 )
            );
       return brws;
    }
    
    function getCover(uint h, uint e ) public pure returns(string memory){

        string[5] memory c =[
            '',
            '<path d="M185,220a20,20,0,0,0-20-20v40A20,20,0,0,0,185,220Z"/><path d="M305,220a20,20,0,0,0-20-20v40A20,20,0,0,0,305,220Z"/>',
            '<path d="M179.14,205.86,165,220l14.14,14.14A20,20,0,0,0,179.14,205.86Z"/><path d="M299.14,205.86,285,220l14.14,14.14A20,20,0,0,0,299.14,205.86Z"/>',
            '<path d="M165,200a20,20,0,0,0-20,20h40A20,20,0,0,0,165,200Z"/><path d="M285,200a20,20,0,0,0-20,20h40A20,20,0,0,0,285,200Z"/>',
            '<path d="M165,240a20,20,0,0,0,20-20H145A20,20,0,0,0,165,240Z"/><path d="M285,240a20,20,0,0,0,20-20H265A20,20,0,0,0,285,240Z"/>'
        ];

        string[2]memory l = [
            '<path d="M313,220a28,28,0,0,0-.66-6.05,28,28,0,0,0-41.68,30.1A28,28,0,0,0,313,220Z"/><path d="M193,220a28,28,0,0,0-.66-6.05,28,28,0,0,0-41.68,30.1A28,28,0,0,0,193,220Z" />',
            '<rect x="165" y="212" width="145" height="33"/>'
        ];
                
        string[3]memory b = [
            '<path d="M165,240c11.05,0,20-5.95,20-17H145C145,234.05,154,240,165,240Z"/><path d="M285,240c11.05,0,20-5.95,20-17H265C265,234.05,274,240,285,240Z"/><path d="M165,200c-11.05,0-20,5.95-20,17h40C185,206,176.05,200,165,200Z" /><path d="M285,200c-11.05,0-20,5.95-20,17h40C305,206,296.05,200,285,200Z"/>',
            '<path d="M165,240c11.05,0,20-2.95,20-14H145C145,237.05,154,240,165,240Z"/><path d="M285,240c11.05,0,20-2.95,20-14H265C265,237.05,274,240,285,240Z"/>',
            '<path d="M165,200c-11.05,0-20,2.95-20,14h40C185,203,176.05,200,165,200Z"/><path d="M285,200c-11.05,0-20,2.95-20,14h40C305,203,296.05,200,285,200Z"/>'
        ];
        

        string memory cover = string(
                abi.encodePacked(
                    c[e],
                    '<g id="blnk" visibility="hidden">',
                    e<3 ? b[0] : b[e-2],
                    '</g>',
                    '<g fill="#fff" opacity="0.15">',
                     l[h],
                    '</g>'
                    
                )
            );
        
        return cover;
    }

    function getPkt(uint t) public pure returns(string memory){
        
          string memory pkt;
        if(t == 0 || t == 4){
            pkt = '';
        }else if(t == 1 || t == 5){
            pkt ='<line x1="290" y1="410" x2="340" y2="410" stroke-width="10px"/>';
        }else if(t == 3){
            pkt = '<rect class="w10" x="290" y="409" width="50" height="30" rx="7.63" /><line class="r10" x1="290" y1="410" x2="340" y2="410"/>';
        }else if(t == 2 || t == 6){
            pkt = '<line class="w7" x1="210" y1="376" x2="210" y2="472"/><line class="w7" x1="290" y1="376" x2="290" y2="472"/> ';    
        }else if(t == 7){
            pkt = '<circle cx="210" cy="410" r="7"/><circle cx="210" cy="470" r="7"/>';
        }
        return pkt;
    }

    function getOCDForSeed( OCDRands memory ocd) public pure returns (string memory)
    {
        
        string[22] memory colors = [           
            "2d2d2d","13294d","9565cc","ffc561","2f3087","544fcf","e54470","eaeaea","f8d485","695150",
            "346ae2","0e4a73","df90e7","c750d0","05a4c0","87766e","e4f8e4","98d6e4","7ed08f","c4ef9d",
            "8168ff","e6ff52"
        ];

        string[8] memory colors1 = [           
            "5242ff","c9c3c9","111","ff5982","e34fec","ffd861","00548e","ff9e5a"
        ];       
        
        string memory bg =string(
            abi.encodePacked(
            '<rect x="0" y="0" width="500" height="500" fill="#',
            colors[ocd.bg1],
            '"></rect>',
            '<rect x="0" y="0" width="500" height="440" fill="#',
            colors[ocd.bg2],
            '"></rect>',
            '<line class="c6" x2="500" y1="440" y2="440"/>'
            )
        );
    
      
        
        string[2] memory holes = [
            '<circle cx="285" cy="220" r="28" /><circle cx="165" cy="220" r="28"/>',
            '<rect x="140" y="195" width="170" height="50"/>'
        ];

        string memory box = getBox(ocd.side);

        string memory eyes = string(
            abi.encodePacked('<g fill="#',
            colors[ocd.eyec],
            '">',
            '<circle cx="165" cy="220" r="18" /><circle cx="285" cy="220" r="18"/>',
            "</g>"
            )
        );
 
        string memory brws = string(
            abi.encodePacked('<g stroke="#',
            colors[ocd.brwsc],
            '">',
            getBrws(ocd.brws),
            '</g>',
            getFlap(ocd.flap)
            )
        );

       
        string memory face = string(
            abi.encodePacked(
            holes[ocd.hole],
            eyes,
            getCover(ocd.hole, ocd.eyecover)
            )
        );

    
        string memory shirt = string(
            abi.encodePacked('<g fill="#',
            colors[ocd.shirtc],
            '">',
            '<polyline class="c6" points="140 500 140 360 360 360 360 500"/>',
            '</g>'
            )
        );

        string memory outer = string(
            abi.encodePacked('<g fill="#',
            colors[ocd.outrc],
            '">',
            '<polyline class="c6" points="140 500 140 360 230 360 230 500"/><polyline class="c6" points="270 500 270 360 360 360 360 500"/>'
            '</g>'
            '<rect class="c10" x="230" y="360" width="15" height="140"  opacity="0.35"/>'
            )
        );


        string memory pocket =  (ocd.top == 1 || ocd.top == 5 ) ?
            string(abi.encodePacked(
                '<g stroke="#', 
                colors1[ocd.pktc],
                '">',
                getPkt(ocd.top),
                '</g>' 
            )) : (ocd.top == 7 )  ? string(abi.encodePacked(
                '<g fill="#', 
                colors1[ocd.pktc],
                '">',
                getPkt(ocd.top),
                '</g>' 
            )) : getPkt(ocd.top) ;

    
        string memory body = string(
            abi.encodePacked(
                shirt,
                (ocd.top<3) ? '' : outer,
                pocket
            )
        );
                
        // Build the SVG from various parts
        string memory svg = string(
            abi.encodePacked(
                '<svg viewBox="0 0 500 500" width="750px" height="750px" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" presevAspectRatio="xMidYMid meet"><style>',
                '.s4{stroke-width:4px;}',
                '.s7{stroke-width:7px;}',
                '.r10{stroke:#d60000; stroke-width:10px;}',
                '.w7{stroke:#f9f9f9; stroke-width:7px;}',
                '.w10{fill:#f9f9f9; stroke-width:10px; }',
                '.c2{fill:#9b7f64; stroke-width:10px; }',
                '.c3{fill:#5e4838; stroke-width:10px; }',
                '.c4{fill:#ad927b; stroke-width:10px; }',
                '.c11{fill:#ad927b; stroke-width:7px; }',
                '.c5{fill:#5e4838; stroke-width:7px;}',
                '.c6{stroke-width:10px;}',
                '.c2,.c3,.c4,.c11,.c5,.c6,.s7,.s4{stroke:#262626; stroke-linejoin:round;}',
                '.c7{fill:#5b2424;}',
                '.c8{stroke:#5b2424;}',
                '.c9{stroke:#262626; stroke-width: 1px; fill:none;}',
                '.c10{fill:#262626;}',
                '.c12{fill:#c1ab9d;}',
                '.b{stroke-width:10px;}',
                '</style>'
               
            )
        );
        string memory animation = string(abi.encodePacked(
             
                '<animate id="blnka"  xlink:href="#blnk" attributeName="visibility" values="visible" begin="3s;blnka.end+',
                ocd.blnk,
                's" dur="0.15s"/> '
        ));

    

        svg = string(
            abi.encodePacked(
                svg,
                bg,
                body,
                box,
                brws,
                face,
                animation,
                '</svg>'
            )
        );

        return svg;
    }

}