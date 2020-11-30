import * as React from 'react';
import { IntranetLocation, IntranetTrigger, ExtensionService, TriggerService, ExtensionPointToolboxAction, ExtensionPointToolboxPanelCreationAction } from '@valo/extensibility';
import { ApplicationCustomizerContext } from '@microsoft/sp-application-base';

export default class QuickNews{
    private extensionService: ExtensionService = null;
    private triggerService: TriggerService = null;
    constructor() {
        this.extensionService = ExtensionService.getInstance();
        this.triggerService = TriggerService.getInstance();
      }
    public register(ctx: ApplicationCustomizerContext) {
        this.extensionService.registerExtension({
            id: "ToolboxPanelCreationActionQN",
            location: IntranetLocation.ToolboxAction,
            element: [
              {
                title: "Create quick news",
                icon: "QuickNote",
                description: "Create quick news item",
                onClick: async () => {
                  const trigger = await this.triggerService.registerTrigger(IntranetTrigger.OpenNewsCreationPanel  );
                  if (trigger) {
                    trigger.invokeTrigger();
                  }
                }
              } as ExtensionPointToolboxPanelCreationAction
            ]
          });
      
      
    }
}