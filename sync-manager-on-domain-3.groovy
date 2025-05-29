// Keep Team \ Manager attribute in sync with Team Membership \ Member (on Engineering Department Manager role objects)
// Use Case 1: Team Membership Manager-role object created or updated

// Import module
import com.atlassian.jira.component.ComponentAccessor;

// Set global variables
def final SCRIPTNAME = "sync-manager-on-domain"
def final SOURCE_ATTR = "Domain Members";       // Name of attribute on referenced object whose value is to be retrieved
def final TARGET_ATTR = "Domain Leaders";       // Name of attribute on THIS object that is to be set based on value retrieved from referenced object
def final LOOKUP_REF_ATTR = "Domain";  // Name of attribute on THIS object to use as a lookup, must be an object reference type attribute (relates the Source to the Target object)

// Java setup
def objectFacade = ComponentAccessor.getOSGiComponentInstanceOfType(ComponentAccessor.getPluginAccessor().getClassLoader().findClass("com.riadalabs.jira.plugins.insight.channel.external.api.facade.ObjectFacade"));
def objectTypeAttributeFacade = ComponentAccessor.getOSGiComponentInstanceOfType(ComponentAccessor.getPluginAccessor().getClassLoader().findClass("com.riadalabs.jira.plugins.insight.channel.external.api.facade.ObjectTypeAttributeFacade"));
def objectAttributeBeanFactory = ComponentAccessor.getOSGiComponentInstanceOfType(ComponentAccessor.getPluginAccessor().getClassLoader().findClass("com.riadalabs.jira.plugins.insight.services.model.factory.ObjectAttributeBeanFactory"));

// ===== Starting =====
log.warn("Running script: $SCRIPTNAME")
sleep (1000)

// ===== Get the Source attribute (the Team Members from the Team Membership object) =====
def objectId = object.getId()
log.warn("objectId: $objectId")
def sourceAttr = objectTypeAttributeFacade.loadObjectTypeAttributeBean(object.getObjectTypeId(), SOURCE_ATTR)
def sourceAttrCurrentVal = objectFacade.loadObjectAttributeBean(object.getId(), sourceAttr?.getId())?.getObjectAttributeValueBeans()?.getAt(0)?.getReferencedObjectBeanId()
def lookupAttr = objectTypeAttributeFacade.loadObjectTypeAttributeBean(object.getObjectTypeId(), LOOKUP_REF_ATTR)
def lookupAttrCurrentVal = objectFacade.loadObjectAttributeBean(object.getId(), lookupAttr?.getId())?.getObjectAttributeValueBeans()?.getAt(0)?.getReferencedObjectBeanId()
log.warn("sourceAttr: " + sourceAttr)
log.warn("sourceAttrCurrentVal: " + sourceAttrCurrentVal)
log.warn("lookupAttr: " + lookupAttr)
log.warn("lookupAttrCurrentVal: " + lookupAttrCurrentVal)

// ===== Use Lookup attribute to get Target object (Team) =====
def teamObject = objectFacade.loadObjectBean(lookupAttrCurrentVal)
def targetAttr = objectTypeAttributeFacade.loadObjectTypeAttributeBean(teamObject.getObjectTypeId(), TARGET_ATTR)
def targetAttrCurrentVal = objectFacade.loadObjectAttributeBean(teamObject.getId(), targetAttr?.getId())?.getObjectAttributeValueBeans()?.getAt(0)?.getReferencedObjectBeanId()
log.warn("targetAttr: " + targetAttr)
log.warn("targetAttrCurrentVal: " + targetAttrCurrentVal)


// ===== If Target attribute (Manager) does not match Source attribute (Team Member), then set it =====
if (targetAttrCurrentVal != sourceAttrCurrentVal) {
    try {
		log.warn(" >> Updating Manager attribute from: $sourceAttrCurrentVal to: $targetAttrCurrentVal")
		def TARGET_VAL = sourceAttrCurrentVal
		def newTargetAttrBean = teamObject.createObjectAttributeBean(targetAttr)
		def newTargetAttrValueBean = newTargetAttrBean.createObjectAttributeValueBean()
		log.warn("TARGET_VAL: " + TARGET_VAL)
		log.warn("newTargetAttrBean: " + newTargetAttrBean)
		log.warn("newTargetAttrValueBean: " + newTargetAttrValueBean)

		newTargetAttrValueBean.setValue(targetAttr, TARGET_VAL)
		newTargetAttrBean.objectAttributeValueBeans.add(newTargetAttrValueBean)
		objectFacade.storeObjectAttributeBean(newTargetAttrBean)
	}		
	catch (Exception e) {
		log.warn("Could not update object attribute due to validation exception: " + e.getMessage());
	}
}

log.warn("Ending script: $SCRIPTNAME")