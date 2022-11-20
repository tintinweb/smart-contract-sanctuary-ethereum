// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract regl {
    // should be almost always way under the limit
    string public constant dataLast = "256);'stencil'in b&&(l.clearStencil(b.stencil|0),c|=1024);l.clear(c)}function v(a){E.push(a);c();return{cancel:function(){function b(){var a=Bb(E,b);E[a]=E[E.length-1];--E.length;0>=E.length&&e()}var c=Bb(E,a);E[c]=b}}}function k(){var a=Q.viewport,b=Q.scissor_box;a[0]=a[1]=b[0]=b[1]=0;H.viewportWidth=H.framebufferWidth=H.drawingBufferWidth=a[2]=b[2]=l.drawingBufferWidth;H.viewportHeight=H.framebufferHeight=H.drawingBufferHeight=a[3]=b[3]=l.drawingBufferHeight}function u(){H.tick+=1;H.time=x();k();I.procs.poll()}function m(){A.refresh();k();I.procs.refresh();t&&t.update()}function x(){return(Cb()-G)/1E3}a=Hb(a);if(!a)return null;var l=a.gl,g=l.getContextAttributes();l.isContextLost();var h=Ib(l,a);if(!h)return null;var r=Eb(),p={vaoCount:0,bufferCount:0,elementsCount:0,framebufferCount:0,shaderCount:0,textureCount:0,cubeCount:0,renderbufferCount:0,maxTextureUnits:0},w=h.extensions,t=$b(l,w),G=Cb(),C=l.drawingBufferWidth,J=l.drawingBufferHeight,H={tick:0,time:0,viewportWidth:C,viewportHeight:J,framebufferWidth:C,framebufferHeight:J,drawingBufferWidth:C,drawingBufferHeight:J,pixelRatio:a.pixelRatio},C={elements:null,primitive:4,count:-1,offset:0,instances:-1},M=Yb(l,w),y=Jb(l,p,a,function(a){return K.destroyBuffer(a)}),T=Kb(l,w,y,p),K=Sb(l,w,M,p,y,T,C),F=Tb(l,r,p,a),A=Nb(l,w,M,function(){I.procs.poll()},H,p,a),O=Zb(l,w,M,p,a),S=Rb(l,w,M,A,O,p),I=Wb(l,r,w,M,y,T,A,S,{},K,F,C,H,t,a),r=Ub(l,S,I.procs.poll,H,g,w,M),Q=I.next,N=l.canvas,E=[],R=[],U=[],Z=[a.onDestroy],ca=null;N&&(N.addEventListener('webglcontextlost',f,!1),N.addEventListener('webglcontextrestored',d,!1));var aa=S.setFBO=q({framebuffer:Y.define.call(null,1,'framebuffer')});m();g=L(q,{clear:function(a){if('framebuffer'in a)if(a.framebuffer&&'framebufferCube'===a.framebuffer_reglType)for(var b=0;6>b;++b)aa(L({framebuffer:a.framebuffer.faces[b]},a),n);else aa(a,n);else n(null,a)},prop:Y.define.bind(null,1),context:Y.define.bind(null,2),'this':Y.define.bind(null,3),draw:q({}),buffer:function(a){return y.create(a,34962,!1,!1)},elements:function(a){return T.create(a,!1)},texture:A.create2D,cube:A.createCube,renderbuffer:O.create,framebuffer:S.create,framebufferCube:S.createCube,vao:K.createVAO,attributes:g,frame:v,on:function(a,b){var c;switch(a){case 'frame':return v(b);case 'lost':c=R;break;case 'restore':c=U;break;case 'destroy':c=Z}c.push(b);return{cancel:function(){for(var a=0;a<c.length;++a)if(c[a]===b){c[a]=c[c.length-1];c.pop();break}}}},limits:M,hasExtension:function(a){return 0<=M.extensions.indexOf(a.toLowerCase())},read:r,destroy:function(){E.length=0;e();N&&(N.removeEventListener('webglcontextlost',f),N.removeEventListener('webglcontextrestored',d));F.clear();S.clear();O.clear();K.clear();A.clear();T.clear();y.clear();t&&t.clear();Z.forEach(function(a){a()})},_gl:l,_refresh:m,poll:function(){u();t&&t.update()},now:x,stats:p});a.onDone(null,g);return g}});";
    // one less than the total chunks expected
    string[] public chunks;

    function addChunk(string memory chunk) public {
        chunks.push(chunk);
    }
    
    function data() public view returns (string memory) {
        return string(abi.encodePacked(
            chunks[0],
            dataLast
        ));
    }
}