//
//  ShaderScene01.swift
//  InteractiveViewControllerTransitions
//
//  Created by Justin Rhoades on 17.02.18.
//  Copyright © 2018 Justin Rhoades. All rights reserved.
//

import UIKit
import SpriteKit
import CoreImage

class ShaderScene01: SKScene {
    
    var shaderNode = SKSpriteNode(imageNamed: "dummypixel")
    
    override func didChangeSize(_ oldSize: CGSize) {
        shaderNode.size = CGSize(width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height)
    }

    override func didMove(to view: SKView) {
        
        backgroundColor = UIColor.clear
        view.backgroundColor = UIColor.clear
        
        // Shaders work with pixels, not points, store scale for use below
        let scale = UIScreen.main.scale
        
        // Create the shader from a bundled shader file
        let starfieldShader = SKShader(fileNamed: "starfieldShader.fsh")
        starfieldShader.uniforms = [
            SKUniform(
                name: "size",
                vectorFloat3: vector_float3(Float(scale * UIScreen.main.bounds.width), Float(scale * UIScreen.main.bounds.height), 0)
            ),
        ]
        
        // Add the shader to the sprite node
        shaderNode.shader = starfieldShader
        
        // Add the sprite node to the scene
        addChild(shaderNode)
    }

}
