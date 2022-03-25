#include "DataEvent.h"
#include "../Include/RmlUi/Element.h"
#include "../Include/RmlUi/Log.h"
#include "../Include/RmlUi/Event.h"
#include "DataExpression.h"
#include "DataModel.h"

namespace Rml {

struct DataEventListener : public EventListener {
	DataEventListener(const std::string& type, bool use_capture, const std::string& expression_str)
		: EventListener(type, use_capture)
		, expression(expression_str)
	{ }
	bool Parse(const DataExpressionInterface& expression_interface, bool is_assignment_expression) {
		return expression.Parse(expression_interface, is_assignment_expression);
	}
	void OnDetach(Element *) override {}
	void ProcessEvent(Event& event) override {
		Element* element = event.GetTargetElement();
		DataExpressionInterface expr_interface(element->GetDataModel(), element, &event);
		Variant unused_value_out;
		expression.Run(expr_interface, unused_value_out);
	}
	DataExpression expression;
};

DataEvent::DataEvent(Element* element)
	: attached_element(element->GetObserverPtr())
{}

DataEvent::~DataEvent() {
	if (Element* element = GetElement()) {
		if (listener) {
			element->RemoveEventListener(listener.get());
		}
	}
}

bool DataEvent::Initialize(DataModel& model, Element* element, const std::string& expression_str, const std::string& modifier) {
	assert(element);
	listener = std::make_unique<DataEventListener>(modifier, false, expression_str);
	DataExpressionInterface expr_interface(&model, element);
	if (!listener->Parse(expr_interface, true)) {
		listener.reset();
		return false;
	}
	element->AddEventListener(listener.get());
	return true;
}

Element* DataEvent::GetElement() const {
	return attached_element.get();
}

}
