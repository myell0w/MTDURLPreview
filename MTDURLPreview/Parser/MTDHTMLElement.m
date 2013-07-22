#import "MTDHTMLElement.h"
#import <libxml/tree.h>
#import <libxml/HTMLtree.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@interface MTDHTMLElement () {
    NSMutableDictionary *_attributes;
    NSMutableArray *_content;
    NSArray *_childNodes;
}

@property (nonatomic, strong, readwrite) NSString *name;        // re-defined as read/write

@end

@implementation MTDHTMLElement

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

+ (NSArray *)nodesForXPathQuery:(NSString *)query onHTML:(NSData *)htmlData {
    return [self nodesForXPathQuery:query onHTML:htmlData namespacePrefix:nil namespaceURI:nil];
}

+ (NSArray *)nodesForXPathQuery:(NSString *)query onHTML:(NSData *)htmlData namespacePrefix:(NSString *)namespacePrefix namespaceURI:(NSString *)namespaceURI {
    xmlDocPtr doc = htmlReadMemory([htmlData bytes], (int)[htmlData length], "", NULL, HTML_PARSE_NOWARNING | HTML_PARSE_NOERROR);
    if (doc == NULL) {
		return nil;
    }

	NSArray *result = [MTDHTMLElement mtd_nodesForXPathQuery:query namespacePrefix:namespacePrefix namespaceURI:namespaceURI libXMLDoc:doc];
    xmlFreeDoc(doc);

	return result;
}

+ (instancetype)nodeForXPathQuery:(NSString *)query onHTML:(NSData *)htmlData {
    NSArray *nodes = [self nodesForXPathQuery:query onHTML:htmlData];

    return nodes.count > 0 ? nodes[0] : nil;
}

+ (instancetype)nodeForXPathQuery:(NSString *)query onHTML:(NSData *)htmlData namespacePrefix:(NSString *)namespacePrefix namespaceURI:(NSString *)namespaceURI {
    NSArray *nodes = [self nodesForXPathQuery:query onHTML:htmlData namespacePrefix:namespacePrefix namespaceURI:namespaceURI];

    return nodes.count > 0 ? nodes[0] : nil;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject
////////////////////////////////////////////////////////////////////////

- (NSString *)description {
	NSMutableString *description = [NSMutableString string];
	[description appendFormat:@"<%@", self.name];
	
    for (NSString *attributeName in self.attributes) {
		NSString *attributeValue = self.attributes[attributeName];
		[description appendFormat:@" %@=\"%@\"", attributeName, attributeValue];
	}
	
	if (self.content.count > 0) {
		[description appendString:@">"];
        
		for (id object in self.content) {
			[description appendString:[object description]];
		}
        
		[description appendFormat:@"</%@>", self.name];
	} else {
		[description appendString:@"/>"];
	}
    
	return description;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - MTXPathResultNode
////////////////////////////////////////////////////////////////////////

- (NSArray *)childNodes {
    if (_childNodes == nil) {
        _childNodes = [self.content filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __unused NSDictionary *bindings) {
            return [evaluatedObject isKindOfClass:[MTDHTMLElement class]];
        }]];
    }

    return _childNodes;
}

- (NSString *)contentString {
	for (NSObject *object in self.content) {
		if ([object isKindOfClass:[NSString class]]) {
			return (NSString *)object;
		}
	}
	
	return nil;
}

- (NSString *)contentStringByUnifyingSubnodes {
	NSMutableString *result = nil;
	
	for (NSObject *object in self.content) {
		if ([object isKindOfClass:[NSString class]]) {
			if (!result) {
				result = [NSMutableString stringWithString:(NSString *)object];
			} else {
				[result appendString:(NSString *)object];
			}
		} else {
			NSString *subnodeResult = [(MTDHTMLElement *)object contentStringByUnifyingSubnodes];
			
			if (subnodeResult) {
				if (!result) {
					result = [NSMutableString stringWithString:subnodeResult];
				} else {
					[result appendString:subnodeResult];
				}
			}
		}
	}
	
	return result;
}

- (MTDHTMLElement *)firstChildNodeWithName:(NSString *)name {
    __block MTDHTMLElement *foundNode = nil;
    
    [self.childNodes enumerateObjectsUsingBlock:^(MTDHTMLElement *element, __unused NSUInteger idx, BOOL *stop) {
        if ([element.name isEqualToString:name]) {
            foundNode = element;
            *stop = YES;
        }
    }];

    return foundNode;
}

- (MTDHTMLElement *)firstChildNodeWithName:(NSString *)name attribute:(NSString *)attributeName attributeValue:(NSString *)attributeValue {
    __block MTDHTMLElement *foundNode = nil;

    [self.childNodes enumerateObjectsUsingBlock:^(MTDHTMLElement *element, __unused NSUInteger idx, BOOL *stop) {
        if ([element.name isEqualToString:name] && [[element attributeWithName:attributeName] isEqualToString:attributeValue]) {
            foundNode = element;
            *stop = YES;
        }
    }];

    return foundNode;
}

- (NSArray *)childNodesWithName:(NSString *)name {
    return [self.childNodes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(MTDHTMLElement *element, __unused NSDictionary *bindings) {
        return [element.name isEqualToString:name];
    }]];
}

- (NSArray *)childNodesTraversingFirstChildWithPath:(NSString *)path {
    NSArray *parts = [path componentsSeparatedByString:@"."];
    __block MTDHTMLElement *element = self;
    __block NSArray *childNodes = nil;

    [parts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger idx, __unused BOOL *stop) {
        // intermediate path component
        if (idx < parts.count - 1) {
            element = [element firstChildNodeWithName:part];
        }

        // last path component
        else {
            childNodes = [element childNodesWithName:part];
        }
    }];

    return childNodes;
}

- (NSArray *)childNodesTraversingAllChildrenWithPath:(NSString *)path {
    NSArray *parts = [path componentsSeparatedByString:@"."];
    __block NSArray *childrenToTraverse = [NSArray arrayWithObject:self];
    __block NSArray *childNodes = nil;

    [parts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger idx, __unused BOOL *stop) {
        NSMutableArray *childrenOfThisStep = [NSMutableArray array];

        for (MTDHTMLElement *element in childrenToTraverse) {
            [childrenOfThisStep addObjectsFromArray:[element childNodesWithName:part]];
        }

        // intermediate path component
        if (idx < parts.count - 1) {
            childrenToTraverse = childrenOfThisStep;
        }

        // last path component
        else {
            childNodes = childrenOfThisStep;
        }
    }];

    return childNodes;
}

- (id)attributeWithName:(NSString *)attributeName {
    return [self.attributes objectForKey:attributeName];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

+ (MTDHTMLElement *)mtd_nodeFromLibXMLNode:(xmlNodePtr)libXMLNode parentNode:(MTDHTMLElement *)parentNode {
	MTDHTMLElement *node = [MTDHTMLElement new];
	
	if (libXMLNode->name) {
		node.name = @((const char *)libXMLNode->name);
	}
	
	if (libXMLNode->content && libXMLNode->type != XML_DOCUMENT_TYPE_NODE) {
		NSString *contentString = [[NSString alloc] initWithCString:(const char *)libXMLNode->content encoding:NSUTF8StringEncoding];
        if (contentString == nil) {
            contentString = [[NSString alloc] initWithCString:(const char *)libXMLNode->content encoding:NSASCIIStringEncoding];
        }
		
		if (contentString != nil && parentNode && (libXMLNode->type == XML_CDATA_SECTION_NODE || libXMLNode->type == XML_TEXT_NODE)) {
			if (libXMLNode->type == XML_TEXT_NODE) {
				contentString = [contentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			}
			
			if (!parentNode.content) {
				parentNode->_content = [NSMutableArray arrayWithObject:contentString];
			} else {
				[parentNode->_content addObject:contentString];
			}
            
			return nil;
		}
	}
	
	xmlAttr *attribute = libXMLNode->properties;
	
    if (attribute) {
		while (attribute) {
			NSString *attributeName = nil;
			NSString *attributeValue = nil;
			
			if (attribute->name && attribute->children && attribute->children->type == XML_TEXT_NODE && attribute->children->content) {
				attributeName = @((const char *)attribute->name);
				attributeValue = @((const char *)attribute->children->content);
				
				if (attributeName && attributeValue) {
					if (!node.attributes) {
						node->_attributes = [NSMutableDictionary dictionaryWithObject:attributeValue forKey:attributeName];
					} else {
						node->_attributes[attributeName] = attributeValue;
					}
				}
			}
			
			attribute = attribute->next;
		}
	}
    
	xmlNodePtr childLibXMLNode = libXMLNode->children;
	
    if (childLibXMLNode) {
		while (childLibXMLNode) {
			MTDHTMLElement *childNode = [MTDHTMLElement mtd_nodeFromLibXMLNode:childLibXMLNode parentNode:node];
			
            if (childNode) {
				if (!node.content) {
					node->_content = [NSMutableArray arrayWithObject:childNode];
				} else {
					[node->_content addObject:childNode];
				}
			}
			
			childLibXMLNode = childLibXMLNode->next;
		}
	}
	
	return node;
}

+ (NSArray *)mtd_nodesForXPathQuery:(NSString *)query namespacePrefix:(NSString *)namespacePrefix namespaceURI:(NSString *)namespaceURI libXMLDoc:(xmlDocPtr)doc {
    xmlXPathContextPtr xpathCtx; 
    xmlXPathObjectPtr xpathObj; 
    
    xpathCtx = xmlXPathNewContext(doc);
    
    if (xpathCtx == NULL) {
		return nil;
    }

    if (namespacePrefix != nil && namespaceURI != nil) {
        xmlXPathRegisterNs(xpathCtx,
                           (xmlChar *)[namespacePrefix cStringUsingEncoding:NSUTF8StringEncoding],
                           (xmlChar *)[namespaceURI cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    
    xpathObj = xmlXPathEvalExpression((xmlChar *)[query cStringUsingEncoding:NSUTF8StringEncoding], xpathCtx);
    
    if(xpathObj == NULL) {
        xmlXPathFreeContext(xpathCtx); 
		return nil;
    }
	
	xmlNodeSetPtr nodes = xpathObj->nodesetval;
	
    if (!nodes) {
        xmlXPathFreeObject(xpathObj);
        xmlXPathFreeContext(xpathCtx);
		return nil;
	}
	
	NSMutableArray *resultNodes = [NSMutableArray array];
	
    for (NSInteger i = 0; i < nodes->nodeNr; i++) {
		MTDHTMLElement *node = [MTDHTMLElement mtd_nodeFromLibXMLNode:nodes->nodeTab[i] parentNode:nil];
		
        if (node) {
			[resultNodes addObject:node];
		}
	}
    
    xmlXPathFreeObject(xpathObj);
    xmlXPathFreeContext(xpathCtx); 
    
    return resultNodes;
}

@end

