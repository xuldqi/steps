import { FrameNode, NodeController, RenderNode } from '@ohos.arkui.node';
import { UIContext } from '@ohos.arkui.UIContext';

export class RuleNodeController extends NodeController{
  private rootNode: FrameNode | null = null;

  makeNode(uiContext: UIContext): FrameNode{
    this.rootNode = new FrameNode(uiContext)
    if (this.rootNode == null) {
      return this.rootNode
    }
    const renderNode = this.rootNode.getRenderNode()
    if (renderNode != null) {
      renderNode.frame = { x: 0, y: 0, width: 10, height: 500 }
      renderNode.pivot = { x: 50, y: 50 }
    }
    return this.rootNode
  }

  addNode(node: RenderNode): void {
    if (this.rootNode == null) {
      return
    }
    const renderNode = this.rootNode.getRenderNode()
    if (renderNode != null) {
      renderNode.appendChild(node)
    }
  }
}
